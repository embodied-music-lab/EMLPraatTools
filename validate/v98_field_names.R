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
# scan_dialog_blocks — read one source file and return its dialogs, each with
# its fields and each field with the branch path it renders on.
#
# STRUCTURE IS MATCHED ON THE LINE WITH ITS STRING LITERALS BLANKED and its
# whole-line comments dropped. eml-output.praat documents its own pause
# protocol in a comment block that contains the line "clicked = endPause:
# ..."; matched raw, that comment closes a dialog forty lines early and every
# field after it disappears from the check.
#
# THE TERMINATOR IS NOT ANCHORED, and that is the point of rewriting this.
# Praat's endPause RETURNS the button number, so the tree writes it as
# `clicked = endPause: ...`. Of the 129 dialogs in the plugin, 32 end on a
# line that begins with the terminator and 97 do not. Anchored at the start
# of the line, as this file matched it until now, those 97 dialogs never
# closed: their field lists were thrown away when the next dialog opened, and
# the collision check ran on 32 dialogs out of 129. It reported no collisions
# because it was barely looking.
# ---------------------------------------------------------------------------
scan_dialog_blocks <- function(path) {
    code <- readLines(path, warn = FALSE)
    blocks <- list()
    open <- FALSE; fields <- list(); stack <- list(); ctr <- 0L; start <- NA_integer_
    unclosed <- character(0)

    field_re <- paste0("^\\s*(", paste(FIELD_KINDS, collapse = "|"),
                       ")\\s*:\\s*\"([^\"]*)\"")

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

        # Branch bookkeeping. elsif/elif are tested before else, and else
        # before if, so that no keyword is claimed by a shorter pattern.
        if (grepl("^\\s*(elsif|elif)\\b", struct)) {
            if (length(stack))
                stack[[length(stack)]]$branch <- stack[[length(stack)]]$branch + 1L
        } else if (grepl("^\\s*else\\b", struct)) {
            if (length(stack))
                stack[[length(stack)]]$branch <- stack[[length(stack)]]$branch + 1L
        } else if (grepl("^\\s*if\\b", struct)) {
            ctr <- ctr + 1L
            stack[[length(stack) + 1L]] <- list(id = ctr, branch = 1L)
        } else if (grepl("^\\s*endif\\b", struct)) {
            if (length(stack)) stack[[length(stack)]] <- NULL
        }

        m <- regmatches(raw, regexec(field_re, raw))[[1]]
        if (length(m) == 3L) {
            branch <- if (length(stack))
                stats::setNames(vapply(stack, function(x) x$branch, integer(1)),
                                vapply(stack, function(x) as.character(x$id),
                                       character(1)))
            else stats::setNames(integer(0), character(0))
            lab <- m[3]
            # A label built by concatenation whose literal part carries no
            # "(" has its derived name finished at run time by whatever is
            # appended. The literal can still be checked; the finished name
            # cannot. Flagged, and pinned below.
            dyn <- !grepl("(", lab, fixed = TRUE) &&
                   grepl("^\\s*[a-z]+\\s*:\\s*\"[^\"]*\"\\s*\\+", raw)
            fields[[length(fields) + 1L]] <- list(
                line = i, label = lab, kind = m[2],
                prefix = praat_field_prefix(lab), branch = branch, dynamic = dyn)
        }
    }
    if (open)
        unclosed <- sprintf("%s: dialog opened at line %d never closed",
                            basename(path), start)
    list(blocks = blocks, unclosed = unclosed)
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

plugin_files <- function() {
    root <- repo_path("plugin_EML_StatsGraphs")
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
    n_fields <- 0L; n_blocks <- 0L

    for (f in files) {
        sc <- scan_dialog_blocks(f)
        unclosed <- c(unclosed, sc$unclosed)
        n_blocks <- n_blocks + length(sc$blocks)
        for (blk in sc$blocks) {
            n_fields <- n_fields + length(blk$fields)
            for (fl in blk$fields) {
                where <- sprintf("%s:%d  \"%s\"", basename(f), fl$line, fl$label)
                if (!grepl(LEGAL_LABEL_RE, label_head(fl$label)))
                    illegal <- c(illegal, sprintf("%s  -> binds %s", where,
                                                  fl$prefix))
                if (!grepl(REACHABLE_RE, fl$prefix))
                    unreachable <- c(unreachable, sprintf("%s  -> binds %s",
                                                          where, fl$prefix))
                if (grepl("-", label_head(fl$label), fixed = TRUE))
                    hyphen <- c(hyphen, where)
                if (fl$dynamic)
                    dynamic <- c(dynamic, sprintf("%s|%s", basename(f), fl$label))
            }
            pre <- vapply(blk$fields, function(x) x$prefix, character(1))
            for (p in unique(pre[duplicated(pre)])) {
                grp <- blk$fields[pre == p]
                for (a in seq_along(grp)) for (b in seq_len(a - 1L)) {
                    rel <- branch_relation(grp[[a]]$branch, grp[[b]]$branch)
                    line <- sprintf("%s: %s <- line %d \"%s\" ; line %d \"%s\"",
                                    basename(f), p,
                                    grp[[b]]$line, grp[[b]]$label,
                                    grp[[a]]$line, grp[[a]]$label)
                    key <- sprintf("%s|%s|%s|%s", basename(f), p,
                                   grp[[b]]$label, grp[[a]]$label)
                    if (rel == "together") together <- c(together, line)
                    else if (rel == "apart") apart <- c(apart, line)
                    else unknown <- c(unknown, key)
                }
            }
        }
    }
    list(n_fields = n_fields, n_blocks = n_blocks, illegal = illegal,
         unreachable = unreachable, together = together, apart = apart,
         unknown = unknown, dynamic = dynamic, unclosed = unclosed,
         hyphen = hyphen)
}

shipped <- audit_files(plugin_files())

cat(sprintf("v98: %d dialog blocks, %d fields\n",
            shipped$n_blocks, shipped$n_fields))

if (length(shipped$unclosed)) {
    cat("DIALOGS THAT NEVER CLOSED:\n")
    cat(paste0("  ", shipped$unclosed, "\n"))
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
                                 "branch_collision.praat")))))

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

if (!exists("EML_SUITE")) { eml_report("v98 dialog field names derive what the code reads"); eml_exit() }
