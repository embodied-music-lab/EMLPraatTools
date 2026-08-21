# ============================================================================
# v98 — every dialog field's label derives the variable name the code reads
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Praat does not let a script name a form field's variable. It DERIVES the
# name from the label, and the derivation is not the tidying-up a reader
# expects. MEASURED on 6.6.30, headless, one field per probe:
#
#   1. The label is cut at the first "(", and exactly ONE space in front of
#      that "(" goes with it. "Gap   (x)" binds `gap__` — two of the three
#      spaces survive. Nothing else is trimmed: "Trailing space " binds
#      `trailing_space_` and "  Padded  name  " binds `__Padded__name__`.
#   2. The FIRST character is lowercased. Only the first: "Voice Type" binds
#      `voice_Type`, "NoGap(y)" binds `noGap`.
#   3. Every space becomes an underscore.
#   4. EVERY OTHER CHARACTER IS KEPT VERBATIM. Nothing is dropped, nothing is
#      translated, and nothing stops the name early.
#   5. word, sentence, text, infile, outfile and folder bind name$; boolean,
#      integer, real, positive and natural bind name; choice and optionmenu
#      bind BOTH name and name$.
#
# STEP 4 IS THE WHOLE PROBLEM, and it is worse than the "truncates at the
# first odd character" story this file used to tell. A label of "left
# Y-limits" does bind a variable. The variable's name is `left_Y-limits`,
# hyphen and all. It holds what the user typed and NO SCRIPT CAN EVER NAME
# IT, because the moment those characters are written the parser reads
# `left_Y` minus `limits`.
#
# An unreachable variable would be survivable if reading it raised "Unknown
# variable": the wrapper would stop and somebody would see it. What actually
# happens is that both halves of an unreachable name are ordinary identifiers
# and a drawing page has a dozen of each in scope. MEASURED: with `limits` =
# 100 and `left_Y` = 1 in scope — bystanders, not contrivances — the user
# types 5 into the "left Y-limits" box and the line that means to read their
# 5 evaluates to -99. No error, no warning, a figure drawn to a range nobody
# asked for. validate/fixtures/dialog_labels/trap_minus99.praat is that
# script, and harness/labellaw/run.sh runs it so the number is measured
# rather than remembered.
#
# So docs/RULING_DIALOG_LABELS_v3.md states THE LABEL CHARACTER LAW: before
# the parenthetical, a field label carries letters, digits and spaces ONLY
# (the leading left/right pairing word is letters, so it needs no exemption).
# Everything decorative — icons, slashes, middle dots, hyphens, units — lives
# inside the parenthetical, which Praat has already thrown away by then. That
# is a rule about the label, checkable by reading, and it is the reason this
# file checks the character class directly rather than checking the symptom.
#
# AND THE SECOND HALF OF THE RULING: uniqueness is judged ON THE DERIVATION
# PREFIX, PER RENDERED PAGE. The parenthetical is not part of the name, so
# "left Value (bottom/top)" and "left Value (left/right)" are one variable.
# MEASURED: Praat draws both rows, with their full labels, and binds the last
# — 111 and 222 discarded, 333 and 444 kept, no error.
# validate/fixtures/dialog_labels/collide_same_noun.praat is that script.
#
# WHAT "PER RENDERED PAGE" MEANS HERE, AND WHAT IT DOES NOT.
#
# A dialog written with conditionals is several pages sharing one block, and
# the tree does that on purpose: thirteen graph pages share one beginPause
# with an advanced branch inside it. Two fields in OPPOSITE branches of one
# `if` never appear together and may share a name; two fields that DO appear
# together may not. So the block is parsed, not just scanned: every field
# carries the branch path it sits on, and a pair is judged three ways.
#
#   PROVABLY TOGETHER — same branch path, or one path an ancestor of the
#       other (the top of the block is an ancestor of everything). Whenever
#       the deeper row renders, the shallower one renders too. This is the
#       collision the ruling demonstrates, and it FAILS.
#   PROVABLY APART — two different branches of the SAME `if`. Legal, and it
#       has to stay legal, or the check pushes the tree into renaming fields
#       that were never in conflict.
#   NEITHER — two different `if`s whose conditions happen to exclude each
#       other. `if a and config_showAdvanced = 0` versus `if
#       config_showAdvanced` is safe, and no parser that does not evaluate
#       Praat expressions can know it. These are NOT failed and NOT ignored:
#       the set of them is pinned below, so the one reviewed case stays
#       green and a new one goes red and gets read by a person.
#
# AND A RENDERED PAGE IS NOT ONLY WHAT IS WRITTEN BETWEEN beginPause AND
# endPause. A `form:` block is a declaration Praat reads whole; a beginPause
# block is ORDINARY CODE, run top to bottom, so a procedure called from inside
# one emits its field rows INTO that dialog. The rows land on the caller's
# page, in the caller's namespace, under names derived from labels written in
# another file. The tree does this: @emlWrapperCommonFields is declared in
# stats/eml-output.praat, ten wrapper dialogs call it, and eleven sites read
# the `clear_Info_window` it binds. So a call made inside a block is FOLLOWED,
# and the rows it contributes are audited as rows of the page that called it,
# carrying the call site's branch path.
#
# MEASURED, 6.6.30 under Xvfb, by harness/labellaw/inject.sh on
# validate/fixtures/dialog_labels/inject_collision.praat: a block writing two
# range rows and calling one procedure rendered FIVE fields, three of them the
# procedure's; the procedure's two range rows collided with the block's own
# and bound last, so left_Value came back 333 and right_Value 444 while the
# block's 111 and 222 vanished; and the procedure's "left Y-limits" row bound
# a value no script can name, reading back as -99.
#
# A call this file cannot follow is FAILED rather than skipped. An unread
# procedure is part of a rendered page nobody has looked at, and from here it
# is indistinguishable from a page with nothing on it.
#
# The honest statement of what this catches: it is a SOURCE check. It proves
# co-rendering from block structure alone. It cannot evaluate a condition, it
# cannot follow a label assembled at run time past the point of assembly (the
# few that exist are pinned below too), and it says nothing about the same
# name on two different pages — that is v99's subject, and deliberate.
#
# Base R only. No packages.

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

FIELD_KINDS <- c("boolean", "integer", "real", "positive", "natural",
                 "word", "sentence", "text", "choice", "optionmenu",
                 "infile", "outfile", "folder")

# ---------------------------------------------------------------------------
# praat_field_prefix — Praat's derivation, reimplemented from the probes in
# the header. Returns the DERIVATION PREFIX: the stored name without the "$"
# a string field appends, because the prefix is what the ruling judges
# uniqueness on and what the character law is a rule about.
#
# The one-space rule matters. trimws() would report "Gap   (x)" as `gap`,
# which is a name that does not exist and would hide a collision with a real
# `gap` elsewhere on the page.
# ---------------------------------------------------------------------------
praat_field_prefix <- function(label) {
    if (grepl("(", label, fixed = TRUE)) {
        s <- sub("\\(.*$", "", label)
        s <- sub(" $", "", s)
    } else {
        s <- label
    }
    if (nchar(s) > 0L)
        s <- paste0(tolower(substr(s, 1, 1)), substring(s, 2))
    gsub(" ", "_", s)
}

# THE LABEL CHARACTER LAW, as a pattern. Letters, digits and spaces, opening
# on a letter — because a name that opens on a digit or an underscore is as
# unreachable as one carrying a hyphen.
LEGAL_LABEL_RE <- "^[A-Za-z][A-Za-z0-9 ]*$"

# What Praat can be asked for by name afterwards. A derived prefix that fails
# this is bound and unreachable: the value is in there and the script cannot
# ask for it.
REACHABLE_RE <- "^[a-zA-Z][A-Za-z0-9_]*$"

label_head <- function(label) {
    if (grepl("(", label, fixed = TRUE)) sub(" $", "", sub("\\(.*$", "", label))
    else label
}

# ---------------------------------------------------------------------------
# THE ROW WALKER'S THREE PIECES, shared by the block scanner and the procedure
# resolver below so that one set of rules governs both.
#
# branch_step  advances the `if` stack for one line. elsif/elif are tested
#              before else, and else before if, so no keyword is claimed by a
#              shorter pattern. Branch ids are strings carrying the walker's
#              own prefix, which keeps a procedure body's `if`s distinct from
#              the caller's.
# stack_branch turns the stack into the named vector a field carries, on top
#              of whatever path the caller was already on.
# read_field   parses one field line into the record the audit reads.
# ---------------------------------------------------------------------------
FIELD_RE <- paste0("^\\s*(", paste(FIELD_KINDS, collapse = "|"),
                   ")\\s*:\\s*\"([^\"]*)\"")

# A dialog block runs the procedures it calls, in place. Praat writes the call
# as `@name`, `@name: args` or `call name`.
CALL_RE <- "^\\s*(@\\s*|call\\s+)([A-Za-z0-9_.]+)"

branch_step <- function(struct, stack, ctr, prefix) {
    if (grepl("^\\s*(elsif|elif)\\b", struct)) {
        if (length(stack))
            stack[[length(stack)]]$branch <- stack[[length(stack)]]$branch + 1L
    } else if (grepl("^\\s*else\\b", struct)) {
        if (length(stack))
            stack[[length(stack)]]$branch <- stack[[length(stack)]]$branch + 1L
    } else if (grepl("^\\s*if\\b", struct)) {
        ctr <- ctr + 1L
        stack[[length(stack) + 1L]] <-
            list(id = paste0(prefix, ctr), branch = 1L)
    } else if (grepl("^\\s*endif\\b", struct)) {
        if (length(stack)) stack[[length(stack)]] <- NULL
    }
    list(stack = stack, ctr = ctr)
}

stack_branch <- function(stack, base) {
    here <- if (length(stack))
        stats::setNames(vapply(stack, function(x) x$branch, integer(1)),
                        vapply(stack, function(x) x$id, character(1)))
    else stats::setNames(integer(0), character(0))
    c(base, here)
}

read_field <- function(raw, file, line, branch, via) {
    m <- regmatches(raw, regexec(FIELD_RE, raw))[[1]]
    if (length(m) != 3L) return(NULL)
    lab <- m[3]
    # A label built by concatenation whose literal part carries no "(" has its
    # derived name finished at run time by whatever is appended. The literal
    # can still be checked; the finished name cannot. Flagged, and pinned
    # below.
    dyn <- !grepl("(", lab, fixed = TRUE) &&
           grepl("^\\s*[a-z]+\\s*:\\s*\"[^\"]*\"\\s*\\+", raw)
    list(file = file, line = line, label = lab, kind = m[2],
         prefix = praat_field_prefix(lab), branch = branch, dynamic = dyn,
         via = via)
}

# ---------------------------------------------------------------------------
# index_procedures — every procedure body in a file set, keyed by name, so a
# call made inside a dialog block can be followed into the file that defines
# it. @emlWrapperCommonFields is declared in stats/eml-output.praat and called
# from ten wrapper scripts, so the index has to span the whole set rather than
# the file being scanned.
# ---------------------------------------------------------------------------
index_procedures <- function(files) {
    idx <- list()
    for (f in files) {
        code <- readLines(f, warn = FALSE)
        name <- NULL; start <- NA_integer_
        for (i in seq_along(code)) {
            if (grepl("^\\s*procedure\\s+[A-Za-z0-9_.]+", code[i])) {
                name <- sub("^\\s*procedure\\s+([A-Za-z0-9_.]+).*$", "\\1",
                            code[i])
                start <- i
            } else if (grepl("^\\s*endproc\\b", code[i])) {
                if (!is.null(name) && i - 1L >= start + 1L)
                    idx[[name]] <- list(file = f, first = start + 1L,
                                        lines = code[(start + 1L):(i - 1L)])
                name <- NULL
            }
        }
    }
    idx
}

# ---------------------------------------------------------------------------
# proc_fields — the rows a called procedure contributes to the page that calls
# it, with the caller's branch path already on them.
#
# WHY THIS EXISTS. A `form:` block is a declaration Praat reads whole, but a
# beginPause block is ORDINARY CODE that runs top to bottom, and a procedure
# called from inside one emits its field rows into that dialog. The rows are
# written in one file and rendered on a page in another, they land in the
# caller's namespace, and the caller reads them by their derived names —
# @emlWrapperCommonFields declares `boolean: "Clear Info window"` and eleven
# sites across the tree read `clear_Info_window`. A scan that stops at the
# lexical edge of the block cannot see the row, so it cannot see the row's
# label and cannot see it collide with anything on the page.
#
# `chain` and `depth` stop a procedure that calls itself, directly or through
# another, from walking forever. A call that resolves to nothing in the
# audited set is returned as unresolved rather than skipped: an unread
# procedure is a piece of a rendered page the check has not looked at, and
# silence about it would read exactly like a clean page.
#
# TWO CALLS TO ONE PROCEDURE FROM ONE BLOCK are given distinct branch-id
# prefixes, so an `if` inside the procedure body reads as two different `if`s.
# Rows outside any such `if` still compare as together — which is the real
# case, and the one the tree has — while rows inside one land in the
# cannot-rule-on set and get read by a person.
# ---------------------------------------------------------------------------
proc_fields <- function(name, procs, base, prefix, via, depth = 1L,
                        chain = character(0)) {
    if (depth > 8L || name %in% chain)
        return(list(fields = list(), unresolved = character(0)))
    p <- procs[[name]]
    if (is.null(p)) return(list(fields = list(), unresolved = name))

    out <- list(); unres <- character(0)
    stack <- list(); ctr <- 0L
    for (k in seq_along(p$lines)) {
        raw <- p$lines[k]
        if (grepl("^\\s*[#;]", raw)) next
        line <- p$first + k - 1L
        struct <- gsub("\"[^\"]*\"", "\"\"", raw)

        st <- branch_step(struct, stack, ctr, prefix)
        stack <- st$stack; ctr <- st$ctr
        branch <- stack_branch(stack, base)

        fl <- read_field(raw, p$file, line, branch, via)
        if (!is.null(fl)) { out[[length(out) + 1L]] <- fl; next }

        cm <- regmatches(struct, regexec(CALL_RE, struct))[[1]]
        if (length(cm) == 3L) {
            sub <- proc_fields(cm[3], procs, branch,
                               paste0(prefix, k, "."), via,
                               depth + 1L, c(chain, name))
            out <- c(out, sub$fields)
            unres <- c(unres, sub$unresolved)
        }
    }
    list(fields = out, unresolved = unres)
}

# ---------------------------------------------------------------------------
# scan_dialog_blocks — read one source file and return its dialogs, each with
# its fields and each field with the branch path it renders on. Fields a
# called procedure contributes are spliced in at the call site, carrying that
# site's branch path.
#
# STRUCTURE IS MATCHED ON THE LINE WITH ITS STRING LITERALS BLANKED and its
# whole-line comments dropped. eml-output.praat documents its own pause
# protocol in a comment block that contains the line "clicked = endPause:
# ..."; matched raw, that comment closes a dialog forty lines early and every
# field after it disappears from the check.
#
# THE TERMINATOR IS NOT ANCHORED. Praat's endPause RETURNS the button number,
# so the tree writes it as `clicked = endPause: ...`: of the 131 dialogs in
# the plugin, 32 end on a line that begins with the terminator and 99 do not.
# Anchoring it at the start of the line leaves those 99 dialogs open, their
# field lists thrown away when the next dialog opens, and the collision check
# looking at 32 dialogs out of 131.
# ---------------------------------------------------------------------------
scan_dialog_blocks <- function(path, procs = list()) {
    code <- readLines(path, warn = FALSE)
    blocks <- list()
    open <- FALSE; fields <- list(); stack <- list(); ctr <- 0L
    start <- NA_integer_
    unclosed <- character(0); unresolved <- character(0); n_calls <- 0L

    for (i in seq_along(code)) {
        raw <- code[i]
        if (grepl("^\\s*[#;]", raw)) next
        struct <- gsub("\"[^\"]*\"", "\"\"", raw)

        if (!open) {
            if (grepl("^\\s*(form[:[:space:]]|beginPause)", struct)) {
                open <- TRUE; fields <- list(); stack <- list()
                ctr <- 0L; start <- i
            }
            next
        }

        if (grepl("(^|[^A-Za-z0-9_.])(endform|endPause)\\b", struct)) {
            blocks[[length(blocks) + 1L]] <-
                list(file = path, start = start, end = i, fields = fields)
            open <- FALSE
            next
        }

        st <- branch_step(struct, stack, ctr, "b")
        stack <- st$stack; ctr <- st$ctr
        branch <- stack_branch(stack, stats::setNames(integer(0), character(0)))

        fl <- read_field(raw, path, i, branch, NA_character_)
        if (!is.null(fl)) { fields[[length(fields) + 1L]] <- fl; next }

        cm <- regmatches(struct, regexec(CALL_RE, struct))[[1]]
        if (length(cm) == 3L) {
            n_calls <- n_calls + 1L
            via <- sprintf("@%s called at %s:%d", cm[3], basename(path), i)
            sub <- proc_fields(cm[3], procs, branch, sprintf("c%d.", i), via)
            fields <- c(fields, sub$fields)
            if (length(sub$unresolved))
                unresolved <- c(unresolved,
                                sprintf("%s:%d  calls @%s, which is defined in no audited file",
                                        basename(path), i,
                                        paste(sub$unresolved, collapse = ", @")))
        }
    }
    if (open)
        unclosed <- sprintf("%s: dialog opened at line %d never closed",
                            basename(path), start)
    list(blocks = blocks, unclosed = unclosed, unresolved = unresolved,
         n_calls = n_calls)
}

# Two branch paths are PROVABLY EXCLUSIVE when some `if` they share sends
# them down different branches. Otherwise they may co-render, and when
# neither path names an `if` the other does not, they certainly do.
branch_relation <- function(a, b) {
    shared <- intersect(names(a), names(b))
    if (length(shared) && any(a[shared] != b[shared])) return("apart")
    if (setequal(names(a), shared) || setequal(names(b), shared)) return("together")
    "unknown"
}

# EML_DIALOG_SRC points the sweep at a tree other than the shipped one. It is
# how the red demonstrations are run: a copy of the plugin with one violating
# label seeded into it, audited by this file unmodified, so the failure shown
# is this check's own failure and not a rehearsal of it.
plugin_files <- function() {
    root <- Sys.getenv("EML_DIALOG_SRC", unset = "")
    if (!nzchar(root)) root <- repo_path("plugin_EML_StatsGraphs")
    if (!dir.exists(root)) stop("dialog source tree not found: ", root)
    f <- list.files(root, pattern = "\\.praat$", recursive = TRUE,
                    full.names = TRUE)
    f[!grepl("/dev/", f, fixed = TRUE)]
}

# ---------------------------------------------------------------------------
# audit_files — the whole check, over any set of source files. The fixtures
# are run through the same function as the shipped tree, so a rule that stops
# firing on the tree stops firing on the seeded violations too.
# ---------------------------------------------------------------------------
audit_files <- function(files) {
    illegal <- character(0); unreachable <- character(0)
    together <- character(0); apart <- character(0); unknown <- character(0)
    dynamic <- character(0); unclosed <- character(0); hyphen <- character(0)
    unresolved <- character(0)
    n_fields <- 0L; n_blocks <- 0L; n_calls <- 0L; n_injected <- 0L

    # The index spans the whole set before any file is scanned, because the
    # procedure a dialog calls is routinely declared in another file.
    procs <- index_procedures(files)

    for (f in files) {
        sc <- scan_dialog_blocks(f, procs)
        unclosed <- c(unclosed, sc$unclosed)
        unresolved <- c(unresolved, sc$unresolved)
        n_calls <- n_calls + sc$n_calls
        n_blocks <- n_blocks + length(sc$blocks)
        for (blk in sc$blocks) {
            n_fields <- n_fields + length(blk$fields)
            for (fl in blk$fields) {
                where <- sprintf("%s:%d  \"%s\"", basename(fl$file), fl$line,
                                 fl$label)
                if (!is.na(fl$via)) {
                    where <- sprintf("%s  [%s]", where, fl$via)
                    n_injected <- n_injected + 1L
                }
                if (!grepl(LEGAL_LABEL_RE, label_head(fl$label)))
                    illegal <- c(illegal, sprintf("%s  -> binds %s", where,
                                                  fl$prefix))
                if (!grepl(REACHABLE_RE, fl$prefix))
                    unreachable <- c(unreachable, sprintf("%s  -> binds %s",
                                                          where, fl$prefix))
                if (grepl("-", label_head(fl$label), fixed = TRUE))
                    hyphen <- c(hyphen, where)
                if (fl$dynamic)
                    dynamic <- c(dynamic, sprintf("%s|%s", basename(fl$file),
                                                  fl$label))
            }
            pre <- vapply(blk$fields, function(x) x$prefix, character(1))
            for (p in unique(pre[duplicated(pre)])) {
                grp <- blk$fields[pre == p]
                for (a in seq_along(grp)) for (b in seq_len(a - 1L)) {
                    rel <- branch_relation(grp[[a]]$branch, grp[[b]]$branch)
                    # The page is named by the block that renders the pair; a
                    # row a procedure contributes is named by the file it is
                    # written in, which is where a reader goes to fix it.
                    line <- sprintf("%s page at line %d: %s <- %s:%d \"%s\" ; %s:%d \"%s\"",
                                    basename(f), blk$start, p,
                                    basename(grp[[b]]$file), grp[[b]]$line,
                                    grp[[b]]$label,
                                    basename(grp[[a]]$file), grp[[a]]$line,
                                    grp[[a]]$label)
                    key <- sprintf("%s|%s|%s|%s", basename(f), p,
                                   grp[[b]]$label, grp[[a]]$label)
                    if (rel == "together") together <- c(together, line)
                    else if (rel == "apart") apart <- c(apart, line)
                    else unknown <- c(unknown, key)
                }
            }
        }
    }
    list(n_fields = n_fields, n_blocks = n_blocks, n_calls = n_calls,
         n_injected = n_injected, illegal = illegal,
         unreachable = unreachable, together = together, apart = apart,
         unknown = unknown, dynamic = dynamic, unclosed = unclosed,
         hyphen = hyphen, unresolved = unresolved)
}

shipped <- audit_files(plugin_files())

cat(sprintf("v98: %d dialog blocks, %d fields (%d of them contributed by %d procedure calls)\n",
            shipped$n_blocks, shipped$n_fields, shipped$n_injected,
            shipped$n_calls))

if (length(shipped$unclosed)) {
    cat("DIALOGS THAT NEVER CLOSED:\n")
    cat(paste0("  ", shipped$unclosed, "\n"))
}
if (length(shipped$unresolved)) {
    cat("PROCEDURES A DIALOG CALLS AND THIS SWEEP COULD NOT READ:\n")
    cat(paste0("  ", shipped$unresolved, "\n"))
}
if (length(shipped$illegal)) {
    cat("LABELS CARRYING A CHARACTER PRAAT KEEPS IN THE VARIABLE NAME:\n")
    cat(paste0("  ", shipped$illegal, "\n"))
}
if (length(shipped$unreachable)) {
    cat("FIELDS BOUND UNDER A NAME NO SCRIPT CAN WRITE:\n")
    cat(paste0("  ", shipped$unreachable, "\n"))
}
if (length(shipped$together)) {
    cat("TWO FIELDS, ONE NAME, ONE RENDERED PAGE:\n")
    cat(paste0("  ", shipped$together, "\n"))
}

check_true("v98", "the sweep found dialog fields to check",
           shipped$n_fields > 100L)
check_true("v98", "every dialog the sweep opened was closed",
           length(shipped$unclosed) == 0L)

# A dialog block is code, and the procedures it calls emit rows into the page
# it renders. A call this sweep cannot follow is a part of that page nobody
# has read, and it looks from here exactly like a page with nothing on it.
check_true("v98",
           "every procedure a dialog calls was found and read",
           length(shipped$unresolved) == 0L)

# The rows that arrive by procedure call are the ones a lexical scan of the
# block cannot see. Asserting that there ARE some keeps the resolver from
# quietly resolving nothing: @emlWrapperCommonFields alone puts one row on
# each of the ten wrapper pages.
check_true("v98",
           "the rows procedures contribute to a dialog are in the sweep",
           shipped$n_injected >= 10L)

# (a) THE LABEL CHARACTER LAW. The rule, stated as a rule about labels.
check_true("v98",
           "no field label carries anything but letters, digits and spaces before its parenthetical",
           length(shipped$illegal) == 0L)

# The same law stated as its consequence, because the consequence is what
# costs a user their input and the two can be read separately: a label that
# passes the class and still derives an unreachable name would mean the
# derivation reimplemented above has drifted from Praat's.
check_true("v98", "every field is bound under a name a script can write",
           length(shipped$unreachable) == 0L)

# THE HYPHEN, NAMED. The label that shipped broken was "Right-hand axis", and
# the field has since been renamed, so pinning that string would pin a name
# nobody uses. What survives the rename is the rule underneath it. The
# character law above covers the hyphen and everything else; this line stays
# because it names the cause in one word where the law names a class, and
# because the hyphen is the one that reads as ordinary English punctuation
# and so is the one that gets typed again.
if (length(shipped$hyphen)) {
    cat("FIELD LABELS CONTAINING A HYPHEN:\n")
    cat(paste0("  ", shipped$hyphen, "\n"))
}
check_true("v98", "no field label contains a hyphen",
           length(shipped$hyphen) == 0L)

# (b) UNIQUENESS PER RENDERED PAGE.
check_true("v98",
           "no two fields that render on one page derive the same name",
           length(shipped$together) == 0L)

# ---------------------------------------------------------------------------
# THE PAIRS THE PARSER CANNOT RULE ON, PINNED BY NAME.
#
# Two fields in two different `if`s whose conditions exclude each other are
# safe, and nothing short of evaluating Praat can prove it. Silence would
# mean the next such pair — which may be a real collision — arrives unread.
# So the set is pinned: the reviewed entries pass, anything else fails and a
# person looks at it.
#
# Keyed on file, derived name and both labels rather than on line numbers,
# so that editing the file above them does not turn this red. The count is
# asserted alongside, so a second copy of a pinned pair cannot hide behind
# the first one's key.
#
# THE ONE ENTRY, and why it is safe: eml-graphs-form.praat's Line Chart
# column page carries "Y axis label" twice. The first is offered on the
# BEGINNER page for the one case that has nowhere else to name the shared
# axis (`if tsSeriesRole = 1 and tsNNum >= 2 and config_showAdvanced = 0`);
# the second is the advanced branch's own axis-label row (`if
# config_showAdvanced`). config_showAdvanced is 0 in one condition and true
# in the other, so exactly one of the two rows exists on any rendering, and
# the source says so where it stands.
# ---------------------------------------------------------------------------
REVIEWED_UNKNOWN <- c(
    "eml-graphs-form.praat|y_axis_label|Y axis label|Y axis label"
)
new_unknown <- setdiff(shipped$unknown, REVIEWED_UNKNOWN)
if (length(new_unknown)) {
    cat("SHARED NAMES THIS CHECK CANNOT RULE ON — READ THESE:\n")
    cat(paste0("  ", new_unknown, "\n"))
}
check_true("v98",
           "every shared name the parser cannot rule on is one that was reviewed",
           length(new_unknown) == 0L && length(shipped$unknown) ==
               length(REVIEWED_UNKNOWN))

# LABELS FINISHED AT RUN TIME, PINNED THE SAME WAY. A label assembled by
# concatenation is checkable only as far as its literal reaches. Where the
# literal already contains the "(", the derived name is settled inside the
# literal and there is nothing to pin. Where it does not, whatever is
# appended lands INSIDE the name, and only a reader can say whether it can
# carry an illegal character. The one case here appends string$ (iN) — digits
# — and puts the column name, which is user data and can carry anything, on
# the far side of the "(" where Praat discards it. That is the pattern any
# new dynamic label has to follow, and this pin is how a departure from it
# gets noticed.
REVIEWED_DYNAMIC <- c("eml-graphs-form.praat|Series ")
new_dynamic <- setdiff(shipped$dynamic, REVIEWED_DYNAMIC)
if (length(new_dynamic)) {
    cat("FIELD LABELS FINISHED AT RUN TIME — READ THESE:\n")
    cat(paste0("  ", new_dynamic, "\n"))
}
check_true("v98",
           "every label finished at run time is one that was reviewed",
           length(new_dynamic) == 0L)

# ---------------------------------------------------------------------------
# THE SEEDED VIOLATIONS. Three scripts under validate/fixtures/dialog_labels,
# included by nothing, exist to be caught. Running them through the same
# audit as the shipped tree is what keeps this file from going quiet: a rule
# relaxed until the tree passes relaxes here too, and these turn red.
#
# The two that Praat can run headlessly are also DRIVEN, by
# harness/labellaw/run.sh, which is where the -99 and the discarded 111/222
# are measured instead of asserted. This file stays source-only and base R.
# ---------------------------------------------------------------------------
fixdir <- repo_path("validate", "fixtures", "dialog_labels")
fix <- function(n) file.path(fixdir, n)

check_true("v98", "the seeded violations are on disk",
           all(file.exists(fix(c("trap_minus99.praat",
                                 "collide_same_noun.praat",
                                 "branch_collision.praat",
                                 "inject_collision.praat")))))

trap <- audit_files(fix("trap_minus99.praat"))
check_true("v98",
           "the hyphen trap is caught by the character law",
           length(trap$illegal) == 1L)
check_true("v98",
           "the hyphen trap's field is seen to be bound under an unwritable name",
           length(trap$unreachable) == 1L &&
               identical(trap$unreachable, trap$illegal))

same_noun <- audit_files(fix("collide_same_noun.praat"))
check_true("v98",
           "the two-range form is caught as two collisions on one page",
           length(same_noun$together) == 2L)
check_true("v98",
           "the two-range form's labels are otherwise legal",
           length(same_noun$illegal) == 0L)

branchy <- audit_files(fix("branch_collision.praat"))
check_true("v98",
           "the branch fixture's two co-rendering pairs are caught",
           length(branchy$together) == 2L)
# The other half of the same fixture, and the reason the parser exists: the
# pair in opposite branches of one `if` must NOT be reported, or the check
# would be demanding renames the ruling does not ask for.
check_true("v98",
           "the branch fixture's opposite-branch pair is not reported",
           length(branchy$apart) == 2L && length(branchy$unknown) == 0L)

# THE ROWS THAT ARRIVE BY CALL. inject_collision.praat writes two range rows
# between beginPause and endPause and gets three more from @seededCommonRows —
# two that collide with the ones in the block and one carrying a hyphen. A
# scan that stopped at the lexical edge of the block would report a clean page
# with two rows on it, which is what makes this the fixture for the resolver.
#
# harness/labellaw/inject.sh renders the same file under Xvfb and reads the
# damage back: five fields on three displayed rows, left_Value = 333 and
# right_Value = 444 with the block's own 111 and 222 gone, bound = 1 and
# read = -99 for the injected hyphen row.
inj <- audit_files(fix("inject_collision.praat"))
check_true("v98",
           "the injected fixture's rows are followed out of the block into the procedure",
           inj$n_fields == 5L && inj$n_injected == 3L && inj$n_calls == 1L)
check_true("v98",
           "the two ranges a procedure adds are caught as collisions on the calling page",
           length(inj$together) == 2L && length(inj$apart) == 0L &&
               length(inj$unknown) == 0L)
check_true("v98",
           "the character law reaches a label written inside a called procedure",
           length(inj$illegal) == 1L && identical(inj$unreachable, inj$illegal) &&
               grepl("seededCommonRows", inj$illegal))

if (!exists("EML_SUITE")) { eml_report("v98 dialog field names derive what the code reads"); eml_exit() }
