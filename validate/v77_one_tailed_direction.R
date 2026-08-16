# ============================================================================
# v77_one_tailed_direction.R -- a one-tailed p is a fixed-direction test, and
#                               the two-sided p did not move to get it
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. Until 16 August 2026 the parametric tests in
# plugin/stats/eml-inferential.praat computed the one-tailed p as
#
#     .absT = abs (.t)
#     .p = studentQ (.absT, .df)
#
# the smaller tail of the ABSOLUTE statistic. That is a post-hoc directional
# p, not a hypothesis test, and the way to see it is to run the test twice:
#
#     group1 = c(8,9,10,11,12), group2 = c(10,12,14,16,18), tails = 1
#         -> t = -2.5298221281347035, p = 0.022732309485465237
#     the SAME data with the arguments swapped
#         -> t = +2.5298221281347035, p = 0.022732309485465237
#
# The same p, from a test whose stated alternative is directional. A
# fixed-direction test must answer .0227 one way and .9773 the other, and a
# procedure that answers .0227 both ways has told the reader that whichever
# way the data happened to fall was the way they predicted. Reversing the
# groups is the whole experiment; a test that cannot see it is not testing.
#
# THE FIX IS ONE PRAAT FACT, MEASURED ON 6.6.30 RATHER THAN ASSUMED.
# studentQ(t, df) is the SIGNED upper tail P(T >= t): studentQ(2.5298, 7.6) =
# 0.01836, studentQ(-2.5298, 7.6) = 0.98164, studentQ(0, df) = 0.5. Section 1
# drives all three on the binary under test rather than quoting them, because
# every line below depends on that signedness and a Praat that changed it
# would make this whole file agree with itself and with nothing else. So
# pGreater = studentQ(.t, .df) and the defect is the abs().
#
# pLess IS NOT 1 - pGreater, AND THAT IS NOT A STYLE PREFERENCE. The
# subtraction is catastrophic cancellation against 1: a right tail of 5.6e-46
# -- which section 5 actually produces -- comes back from 1 - (1 - 5.6e-46)
# as exactly 0, every significant digit gone, and the reader is handed a p of
# zero for a test that has a perfectly good p. So pLess = studentQ(-.t, .df),
# a second evaluation of the same correctly-rounded tail on the other side,
# and section 5 asserts the small tail survives at full precision beside its
# complement of exactly 1.
#
# THE REGRESSION THAT MATTERS IS THE ONE-SIDED ONE. Every REGISTERED menu
# path in the shipping tree passes tails = 2 -- stats/eml-analysis.praat lines
# 243, 1796 and 3633, and every graphs/ and scripts/ call site besides -- so
# no shipped menu ever printed the defective number, and the entire exposure
# was the public scripting API. That cuts both ways: it also means a repair
# that quietly moved the TWO-sided p would break every shipped report while
# fixing an API nobody could see. Section 3 therefore recomputes all five
# two-sided p-values in R from first principles and pins them to zero
# tolerance. Section 2's static read asserts the scope claim itself, so that a
# future tails = 1 appearing on a menu path goes red here rather than being
# discovered by a reader of the output.
#
# THE TRAP THIS FILE IS BUILT AROUND: THE SYMMETRIC FIX. The cheap way to
# satisfy "reversal changes the answer" is a repair that is still not a test
# -- for instance selecting the tail from the sign of the DIFFERENCE OF MEANS
# rather than from a fixed alternative, or returning min(pGreater, pLess),
# either of which changes under reversal and neither of which is
# alternative = "greater". So the numbers are not merely asserted DIFFERENT
# under reversal: each of the ten one-tailed p-values is pinned against R's
# own t.test(alternative = "greater") and cor.test(alternative = "greater") at
# 1e-12, which is an independent implementation and not a second copy of the
# thing under test. A min() repair passes "they differ" and fails section 4 on
# the wrong-direction row, where R says .977 and min() says .023.
#
# WHAT IS NOT ASSERTED HERE. Spearman's p is the t-approximation on ranks,
# which is what this plugin has always computed and says so in its header; R's
# cor.test(method = "spearman") uses the exact AS 89 permutation distribution
# and answers 0.0011 where the t-approximation answers 0.00043. Section 4
# compares the plugin against cor.test on the RANKS, which is the oracle for
# what it claims to compute. Changing Spearman to the exact distribution is a
# different piece of work and would not be caught by this file.
# ============================================================================

if (!exists("check")) {
    .a <- commandArgs(FALSE)
    .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".",
                     "helpers.R"))
}

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")

# ---------------------------------------------------------------------------
# 0. THE BINARY -- same floor and the same refusal as the other driving files
# ---------------------------------------------------------------------------
praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat_barren"),
                   Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pv <- NA_character_
pvnum <- 0
if (nzchar(praat) && file.exists(praat)) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE,
                                   stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        pvnum <- p[1] * 1000 + p[2] * 100 + p[3]
    }
}
canDrive <- pvnum >= 6630

# ---------------------------------------------------------------------------
# THE DATA. One set, used by every section, so that the static claims, the
# driven numbers and the R oracle are all talking about the same experiment.
# `a` and `b` are the author's stress-test pair from the reproduction above;
# the paired and correlation sets are chosen to have a clear direction and no
# ties, so that "the wrong direction" is unambiguous.
# ---------------------------------------------------------------------------
A  <- c(8, 9, 10, 11, 12)
B  <- c(10, 12, 14, 16, 18)
PA <- c(5.1, 6.3, 4.8, 7.2, 6.0, 5.5, 6.9)
PB <- c(5.9, 6.1, 5.4, 8.0, 6.8, 5.4, 7.6)
CX <- 1:8
CY <- c(2.1, 1.9, 3.8, 3.2, 5.5, 5.1, 6.9, 7.4)

# ---------------------------------------------------------------------------
# 1/2. THE SOURCE, READ STATICALLY FIRST
# ---------------------------------------------------------------------------
# Static before driven, for the reason v63 gives: a run that cannot launch
# Praat should still be able to say whether the thing this file is about has
# changed underneath it. Two claims here are load-bearing and neither is
# checkable from the driven numbers alone.
#
# (a) THE DEFECT'S OWN LINE IS GONE. `.p = studentQ (.absT, .df)` -- the
#     one-tailed selection off the absolute statistic -- must not appear
#     anywhere in the file. The two-sided line `2 * studentQ (.absT, .df)` is
#     the same expression doubled and is CORRECT and must stay, so the pattern
#     is anchored to exclude it.
#
# (b) THE SCOPE CLAIM IS TRUE. Every header rewritten today asserts to the
#     reader that no registered menu path passes tails = 1. That sentence is
#     the reason the severity is what it is, and it is a statement about
#     OTHER files -- so it is checked against those other files, not taken on
#     trust from the one that makes it.
# ---------------------------------------------------------------------------
srcInf <- file.path(plug, "stats", "eml-inferential.praat")
check_true("v77", "stats/eml-inferential.praat is present", file.exists(srcInf))

if (file.exists(srcInf)) {
    inf <- readLines(srcInf, warn = FALSE)

    # (a) the defective selection is gone. Match `.p = studentQ (.absT` with
    #     any spacing, and NOT the two-sided `2 * studentQ (.absT`.
    badP <- grep("\\.p\\s*=\\s*studentQ\\s*\\(\\s*\\.absT", inf)
    check_true("v77",
               sprintf("no one-tailed p is taken from the absolute t (%d such lines)",
                       length(badP)),
               length(badP) == 0)

    # and the two-sided form, which is correct, is STILL THERE -- three of
    # them, one per kernel. A "repair" that deleted the abs() everywhere
    # would break the two-sided p and pass the check above.
    goodP <- grep("2\\s*\\*\\s*studentQ\\s*\\(\\s*\\.absT", inf)
    check("v77", "the two-sided 2 * studentQ(|t|, df) survives in all three kernels",
          length(goodP), 3, tol = 0)

    # the signed tails are computed, and pLess is not a subtraction
    check("v77", "pGreater is studentQ of the SIGNED t, in three kernels",
          length(grep("\\.pGreater\\s*=\\s*studentQ\\s*\\(\\s*\\.t\\s*,", inf)),
          3, tol = 0)
    check("v77", "pLess is studentQ of the negated t, in three kernels",
          length(grep("\\.pLess\\s*=\\s*studentQ\\s*\\(\\s*-\\s*\\.t\\s*,", inf)),
          3, tol = 0)
    check_true("v77",
               "pLess is nowhere computed as 1 - pGreater (catastrophic cancellation)",
               length(grep("\\.pLess\\s*=\\s*1\\s*-", inf)) == 0)

    # THE HEADER SENTENCE THAT DOCUMENTED THE DEFECT AS THE DESIGN IS GONE.
    # The original read "One-tailed p: Tests significance in the direction of
    # the observed effect (i.e., p = studentQ(|t|, df))" -- a specification of
    # the defect, in the voice of an intention. It must not survive anywhere.
    check_true("v77",
               "the old header sentence 'Tests significance in the direction of the observed effect' is gone",
               length(grep("Tests significance in the direction", inf)) == 0)
    # AND THE FORMULA IS NOT QUOTED ANYWHERE EITHER. The shipped headers
    # describe the behaviour the kernels HAVE; a quotation of the |t| formula
    # in a plugin header can only be read as a description of what the
    # procedure does, whatever clause is wrapped round it. The place that
    # formula belongs is this file and the git history, both of which say it
    # plainly above. So the pin is absence, in the plugin, and the two checks
    # under it are on the CODE rather than on any sentence: no kernel takes a
    # one-tailed p from the absolute t, and each takes it from .pGreater.
    check_true("v77",
               "the |t| formula is quoted nowhere in the plugin file",
               length(grep("studentQ\\(\\|t\\|", inf)) == 0)
    check_true("v77",
               "no one-tailed p is taken from the ABSOLUTE t (.p = studentQ(.absT))",
               length(grep("\\.p\\s*=\\s*studentQ\\s*\\(\\s*\\.absT", inf)) == 0)
    check("v77", "the one-tailed arm of each of the three kernels takes .pGreater",
          length(grep("^\\s*\\.p = \\.pGreater\\s*$", inf)), 8, tol = 0)

    # THE HEADERS STATE THE FIXED ALTERNATIVE POSITIVELY, in @emlMannWhitneyU's
    # voice: what .tails = 1 IS, what a wrong-direction test returns, and which
    # output carries the other alternative. Four numeric-argument headers say
    # it (t, paired t, Pearson, Spearman); the two rank tests carry the same
    # sentence, which is why the FIXED-as-H1 count is six.
    check("v77", "each of the four .tails headers says what the argument cannot express",
          length(grep("counts tails and nothing else", inf)), 4, tol = 0)
    check("v77", "every one-tailed header states the FIXED alternative",
          length(grep("the alternative is FIXED as H1", inf)), 6, tol = 0)
    check("v77", "every one-tailed header warns that the wrong direction returns p near 1",
          length(grep("p-value near 1, not near 0", inf)), 5, tol = 0)

    # the four explicit entry points exist
    for (pr in c("emlTTestAlt", "emlTTestPairedAlt",
                 "emlPearsonCorrelationAlt", "emlSpearmanCorrelationAlt")) {
        check_true("v77", sprintf("@%s is defined", pr),
                   any(grepl(sprintf("^procedure %s:", pr), inf)))
    }

    # (b) THE SCOPE CLAIM, checked against the files it is a claim about.
    # Every call to one of the five tests outside dev/ must pass tails = 2.
    # The dev suite is excluded on purpose: it is where tails = 1 SHOULD be
    # exercised, and it is not a shipped path.
    shipped <- setdiff(
        list.files(plug, pattern = "\\.praat$", recursive = TRUE,
                   full.names = TRUE),
        list.files(file.path(plug, "dev"), pattern = "\\.praat$",
                   recursive = TRUE, full.names = TRUE))
    callRe <- paste0("@(emlTTest|emlTTestPaired|emlPearsonCorrelation",
                     "|emlSpearmanCorrelation|emlMannWhitneyU",
                     "|emlWilcoxonSignedRank)\\s*:")
    oneTailed <- character(0)
    nCalls <- 0L
    for (f in shipped) {
        ln <- readLines(f, warn = FALSE)
        hit <- grep(callRe, ln)
        for (i in hit) {
            s <- sub("^\\s*", "", ln[i])
            if (grepl("^[;#]", s)) next          # a comment, not a call
            nCalls <- nCalls + 1L
            # last numeric argument that is not part of a vector name
            args <- strsplit(sub("^@[A-Za-z_]+\\s*:", "", s), ",")[[1]]
            args <- trimws(args)
            # the tails argument is the one that is a bare 1 or 2, or a
            # variable; a bare 1 anywhere in the argument list is the event.
            if (any(args == "1")) oneTailed <- c(oneTailed, sprintf("%s:%d",
                                                 basename(f), i))
        }
    }
    check_true("v77",
               sprintf("some shipped call sites were actually read (%d found)",
                       nCalls),
               nCalls >= 15)
    check_true("v77",
               sprintf("NO registered/shipped call site passes tails = 1%s",
                       if (length(oneTailed))
                           paste0(" -- found at ", paste(oneTailed, collapse = ", "))
                       else ""),
               length(oneTailed) == 0)
}

# ---------------------------------------------------------------------------
# THE DRIVE
# ---------------------------------------------------------------------------
if (!canDrive) {
    cat(paste0("      SKIP: v77 needs Praat >= 6.6.30 to drive the tests;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n",
               "            Static checks above still hold.\n"))
    check_true("v77",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {
    work <- file.path(tempdir(), "v77")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    # A stale lock from a crashed run makes the next Praat refuse to start,
    # and a refusal at startup reads here as a driver that printed nothing.
    # Only these two files, and only in this scratch folder.
    unlink(file.path(prefs, c("pid", "message")))

    # Symlink sandbox, as v63/v64/v65 use: Praat resolves a relative include
    # against the TOP-LEVEL script's folder, and a validator that writes its
    # scratch into the tree it is measuring has started changing that tree.
    tgt <- file.path(work, "stats")
    if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, "stats")), tgt)

    vec <- function(v) paste0("{", paste(format(v, digits = 17), collapse = ", "), "}")

    probe <- file.path(work, "scripts", "v77-probe.praat")
    writeLines(c(
        'include ../stats/eml-core-utilities.praat',
        'include ../stats/eml-core-descriptive.praat',
        'include ../stats/eml-output.praat',
        'include ../stats/eml-inferential.praat',
        '',
        'writeInfoLine: "v77"',
        sprintf('a# = %s', vec(A)),
        sprintf('b# = %s', vec(B)),
        sprintf('pa# = %s', vec(PA)),
        sprintf('pb# = %s', vec(PB)),
        sprintf('cx# = %s', vec(CX)),
        sprintf('cy# = %s', vec(CY)),
        'ncy# = -cy#',
        '',
        '# --- 1. THE PRAAT FACT THE WHOLE REPAIR RESTS ON -------------------',
        '# studentQ is the SIGNED upper tail. Driven, not quoted.',
        'appendInfoLine: "sq|pos|", studentQ (2.5298, 7.6)',
        'appendInfoLine: "sq|neg|", studentQ (-2.5298, 7.6)',
        'appendInfoLine: "sq|zero|", studentQ (0, 7.6)',
        '',
        'procedure emit: .tag$, .pG, .pL, .p, .alt$',
        '    appendInfoLine: .tag$, "|", .pG, "|", .pL, "|", .p, "|", .alt$',
        'endproc',
        '',
        '# --- 3/4. THE FIVE TESTS, EACH RUN BOTH WAYS ROUND -----------------',
        '@emlTTest: a#, b#, 1, 0',
        '@emit: "ot|welch|fwd", emlTTest.pGreater, emlTTest.pLess, emlTTest.p, emlTTest.alternative$',
        '@emlTTest: b#, a#, 1, 0',
        '@emit: "ot|welch|rev", emlTTest.pGreater, emlTTest.pLess, emlTTest.p, emlTTest.alternative$',
        '@emlTTest: a#, b#, 2, 0',
        'appendInfoLine: "ts|welch|", emlTTest.p, "|", emlTTest.t, "|", emlTTest.df, "|", emlTTest.alternative$',
        '',
        '@emlTTest: a#, b#, 1, 1',
        '@emit: "ot|student|fwd", emlTTest.pGreater, emlTTest.pLess, emlTTest.p, emlTTest.alternative$',
        '@emlTTest: b#, a#, 1, 1',
        '@emit: "ot|student|rev", emlTTest.pGreater, emlTTest.pLess, emlTTest.p, emlTTest.alternative$',
        '@emlTTest: a#, b#, 2, 1',
        'appendInfoLine: "ts|student|", emlTTest.p, "|", emlTTest.t, "|", emlTTest.df, "|", emlTTest.alternative$',
        '',
        '@emlTTestPaired: pa#, pb#, 1',
        '@emit: "ot|paired|fwd", emlTTestPaired.pGreater, emlTTestPaired.pLess, emlTTestPaired.p, emlTTestPaired.alternative$',
        '@emlTTestPaired: pb#, pa#, 1',
        '@emit: "ot|paired|rev", emlTTestPaired.pGreater, emlTTestPaired.pLess, emlTTestPaired.p, emlTTestPaired.alternative$',
        '@emlTTestPaired: pa#, pb#, 2',
        'appendInfoLine: "ts|paired|", emlTTestPaired.p, "|", emlTTestPaired.t, "|", emlTTestPaired.df, "|", emlTTestPaired.alternative$',
        '',
        '# For the correlations the reversal is a NEGATED variable, which is',
        '# the same experiment run against the opposite alternative.',
        '@emlPearsonCorrelation: cx#, cy#, 1',
        '@emit: "ot|pearson|fwd", emlPearsonCorrelation.pGreater, emlPearsonCorrelation.pLess, emlPearsonCorrelation.p, emlPearsonCorrelation.alternative$',
        '@emlPearsonCorrelation: cx#, ncy#, 1',
        '@emit: "ot|pearson|rev", emlPearsonCorrelation.pGreater, emlPearsonCorrelation.pLess, emlPearsonCorrelation.p, emlPearsonCorrelation.alternative$',
        '@emlPearsonCorrelation: cx#, cy#, 2',
        'appendInfoLine: "ts|pearson|", emlPearsonCorrelation.p, "|", emlPearsonCorrelation.r, "|", emlPearsonCorrelation.df, "|", emlPearsonCorrelation.alternative$',
        '',
        '@emlSpearmanCorrelation: cx#, cy#, 1',
        '@emit: "ot|spearman|fwd", emlSpearmanCorrelation.pGreater, emlSpearmanCorrelation.pLess, emlSpearmanCorrelation.p, emlSpearmanCorrelation.alternative$',
        '@emlSpearmanCorrelation: cx#, ncy#, 1',
        '@emit: "ot|spearman|rev", emlSpearmanCorrelation.pGreater, emlSpearmanCorrelation.pLess, emlSpearmanCorrelation.p, emlSpearmanCorrelation.alternative$',
        '@emlSpearmanCorrelation: cx#, cy#, 2',
        'appendInfoLine: "ts|spearman|", emlSpearmanCorrelation.p, "|", emlSpearmanCorrelation.rho, "|", emlSpearmanCorrelation.df, "|", emlSpearmanCorrelation.alternative$',
        '',
        '# --- 6. THE EXPLICIT ENTRY POINTS ----------------------------------',
        '@emlTTestAlt: a#, b#, "greater", 0',
        '@emit: "alt|welch|greater", emlTTestAlt.pGreater, emlTTestAlt.pLess, emlTTestAlt.p, emlTTestAlt.alternative$',
        '@emlTTestAlt: a#, b#, "less", 0',
        '@emit: "alt|welch|less", emlTTestAlt.pGreater, emlTTestAlt.pLess, emlTTestAlt.p, emlTTestAlt.alternative$',
        '@emlTTestAlt: a#, b#, "two-sided", 0',
        '@emit: "alt|welch|two-sided", emlTTestAlt.pGreater, emlTTestAlt.pLess, emlTTestAlt.p, emlTTestAlt.alternative$',
        '@emlTTestPairedAlt: pa#, pb#, "less"',
        '@emit: "alt|paired|less", emlTTestPairedAlt.pGreater, emlTTestPairedAlt.pLess, emlTTestPairedAlt.p, emlTTestPairedAlt.alternative$',
        '@emlPearsonCorrelationAlt: cx#, cy#, "less"',
        '@emit: "alt|pearson|less", emlPearsonCorrelationAlt.pGreater, emlPearsonCorrelationAlt.pLess, emlPearsonCorrelationAlt.p, emlPearsonCorrelationAlt.alternative$',
        '@emlSpearmanCorrelationAlt: cx#, cy#, "less"',
        '@emit: "alt|spearman|less", emlSpearmanCorrelationAlt.pGreater, emlSpearmanCorrelationAlt.pLess, emlSpearmanCorrelationAlt.p, emlSpearmanCorrelationAlt.alternative$',
        '',
        '# An unrecognised alternative must REFUSE, not fall back to',
        '# two-sided. A silent fallback is the defect this file is about,',
        '# wearing a string instead of a number.',
        '@emlTTestAlt: a#, b#, "Greater", 0',
        'appendInfoLine: "bad|welch|", emlTTestAlt.error$, "|", emlTTestAlt.p, "|", emlTTestAlt.t',
        '@emlTTestPairedAlt: pa#, pb#, "sideways"',
        'appendInfoLine: "bad|paired|", emlTTestPairedAlt.error$, "|", emlTTestPairedAlt.p, "|", emlTTestPairedAlt.t',
        '@emlPearsonCorrelationAlt: cx#, cy#, ""',
        'appendInfoLine: "bad|pearson|", emlPearsonCorrelationAlt.error$, "|", emlPearsonCorrelationAlt.p, "|", emlPearsonCorrelationAlt.r',
        '@emlSpearmanCorrelationAlt: cx#, cy#, "grater"',
        'appendInfoLine: "bad|spearman|", emlSpearmanCorrelationAlt.error$, "|", emlSpearmanCorrelationAlt.p, "|", emlSpearmanCorrelationAlt.rho',
        '',
        '# --- 5. THE WRONG-DIRECTION PERFECT EFFECT -------------------------',
        '# A separation so large the t is ~1e6. The wrong-direction p must be',
        '# 1 -- not 0, not undefined -- and the RIGHT-direction p must keep',
        '# all its digits, which is what 1 - pGreater would have destroyed.',
        'w1# = {0, 0.0001, -0.0001, 0.0002, -0.0002}',
        'w2# = {100, 100.0001, 99.9999, 100.0002, 99.9998}',
        '@emlTTest: w1#, w2#, 1, 1',
        'appendInfoLine: "ext|huge|", emlTTest.t, "|", emlTTest.pGreater, "|", emlTTest.pLess, "|", emlTTest.p',
        '',
        '# t = -40 exactly, on the same df the kernel uses, straight off the',
        '# binary: the assignment asks for this number by name.',
        'appendInfoLine: "ext|t40|", studentQ (-40, 8), "|", studentQ (40, 8)',
        '',
        '# |r| = 1: t is not a number at all, so the limits are written out',
        '# and the SIGN of r decides which limit is which.',
        'px# = {1, 2, 3, 4, 5}',
        'py# = {2, 4, 6, 8, 10}',
        'npy# = -py#',
        '@emlPearsonCorrelation: px#, py#, 1',
        'appendInfoLine: "ext|perfpos|", emlPearsonCorrelation.r, "|", emlPearsonCorrelation.pGreater, "|", emlPearsonCorrelation.pLess, "|", emlPearsonCorrelation.p, "|", emlPearsonCorrelation.perfect',
        '@emlPearsonCorrelation: px#, npy#, 1',
        'appendInfoLine: "ext|perfneg|", emlPearsonCorrelation.r, "|", emlPearsonCorrelation.pGreater, "|", emlPearsonCorrelation.pLess, "|", emlPearsonCorrelation.p, "|", emlPearsonCorrelation.perfect',
        '@emlPearsonCorrelation: px#, npy#, 2',
        'appendInfoLine: "ext|perfnegts|", emlPearsonCorrelation.p',
        '@emlSpearmanCorrelation: px#, npy#, 1',
        'appendInfoLine: "ext|perfnegsp|", emlSpearmanCorrelation.rho, "|", emlSpearmanCorrelation.pGreater, "|", emlSpearmanCorrelation.pLess, "|", emlSpearmanCorrelation.p',
        '',
        '# --- 7. THE ERROR PATHS LEAVE THE NEW OUTPUTS ALONE ----------------',
        '@emlTTest: a#, b#, 3, 0',
        'appendInfoLine: "err|badtails|", emlTTest.error$, "|", emlTTest.pGreater, "|", emlTTest.pLess, "|[", emlTTest.alternative$, "]"'),
        probe)

    outTxt <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
        stdout = TRUE, stderr = TRUE))

    fld <- function(tag) {
        p <- sprintf("^%s\\|", gsub("\\|", "\\\\|", tag))
        h <- grep(p, outTxt, value = TRUE)
        if (!length(h)) return(character(0))
        strsplit(sub(p, "", h[1]), "|", fixed = TRUE)[[1]]
    }
    num <- function(tag, i) {
        f <- fld(tag)
        if (length(f) < i) return(NA_real_)
        suppressWarnings(as.numeric(f[i]))
    }

    ran <- !any(grepl("^Error", outTxt)) && length(fld("sq|zero")) == 1
    if (!ran) cat(sprintf("      v77 probe output: %s\n",
                          paste(utils::tail(outTxt, 10), collapse = " / ")))
    check_true("v77", "the direction probe ran", ran)

if (ran) {
    # -- 1. THE PREMISE IS TRUE OF THIS BINARY ------------------------------
    # If studentQ were the two-sided or the absolute tail, every number below
    # would be self-consistently wrong. It is asserted before it is used.
    check("v77", "studentQ(+2.5298, 7.6) is the SMALL upper tail",
          num("sq|pos", 1), 0.018360130570908, tol = 1e-12)
    check("v77", "studentQ(-2.5298, 7.6) is the LARGE upper tail (signed, not absolute)",
          num("sq|neg", 1), 0.981639869429092, tol = 1e-12)
    check("v77", "studentQ(0, df) is exactly one half",
          num("sq|zero", 1), 0.5, tol = 0)

    # -- 2. THE REVERSAL MATRIX --------------------------------------------
    # For each test: run it, then run the same data with the two arguments
    # swapped (the correlations negate one variable). Three claims per row.
    #   (i)   pGreater(fwd) == pLess(rev) -- the same tail, named from the
    #         other side. To the last bit, because it IS the same tail.
    #   (ii)  pGreater + pLess == 1 within 1e-12.
    #   (iii) the two one-tailed p-values are on OPPOSITE sides of 0.5, which
    #         is the sentence the defect could not say: the same data, read
    #         the other way round, is not evidence for the hypothesis.
    tests <- c("welch", "student", "paired", "pearson", "spearman")
    for (tst in tests) {
        fG <- num(sprintf("ot|%s|fwd", tst), 1)
        fL <- num(sprintf("ot|%s|fwd", tst), 2)
        rG <- num(sprintf("ot|%s|rev", tst), 1)
        rL <- num(sprintf("ot|%s|rev", tst), 2)
        fP <- num(sprintf("ot|%s|fwd", tst), 3)
        rP <- num(sprintf("ot|%s|rev", tst), 3)

        check("v77", sprintf("%s: pGreater(fwd) is pLess(rev), to the last bit", tst),
              fG, rL, tol = 0)
        check("v77", sprintf("%s: pLess(fwd) is pGreater(rev), to the last bit", tst),
              fL, rG, tol = 0)
        check("v77", sprintf("%s: pGreater + pLess = 1 (forward)", tst),
              fG + fL, 1, tol = 1e-12)
        check("v77", sprintf("%s: pGreater + pLess = 1 (reversed)", tst),
              rG + rL, 1, tol = 1e-12)
        # THE DEFECT ITSELF: at HEAD these two were the SAME number.
        check("v77", sprintf("%s: reversing the arguments MOVES the one-tailed p", tst),
              fP, rP, tol = 1e-9, expect = "differ")
        check_true("v77",
                   sprintf("%s: the one-tailed p straddles .5 under reversal (%.6g vs %.6g)",
                           tst, fP, rP),
                   is.finite(fP) && is.finite(rP) &&
                   ((fP < 0.5 && rP > 0.5) || (fP > 0.5 && rP < 0.5)))
        # .tails = 1 names its alternative, and it is the fixed one.
        check_true("v77", sprintf("%s: .alternative$ is \"greater\" for .tails = 1", tst),
                   identical(fld(sprintf("ot|%s|fwd", tst))[4], "greater"))
    }

    # -- 3. THE TWO-SIDED p DID NOT MOVE -----------------------------------
    # THE REGRESSION THAT MATTERS. Every shipped path is two-sided, so a
    # repair that perturbed these would be a far worse defect than the one it
    # fixed. R recomputes each from the raw data -- not from the plugin's t --
    # and the tolerance is the double epsilon scale, not a display tolerance.
    ts <- list(
        welch    = t.test(A, B)$p.value,
        student  = t.test(A, B, var.equal = TRUE)$p.value,
        paired   = t.test(PA, PB, paired = TRUE)$p.value,
        pearson  = cor.test(CX, CY)$p.value,
        # Spearman here is the plugin's t-approximation on ranks, which is
        # what it documents; cor.test(method="spearman") is a different
        # statistic. See the header.
        spearman = cor.test(rank(CX), rank(CY))$p.value)
    for (tst in names(ts)) {
        check("v77", sprintf("%s two-sided p is unchanged and matches R", tst),
              num(sprintf("ts|%s", tst), 1), ts[[tst]], tol = 1e-14)
        check_true("v77", sprintf("%s: .tails = 2 still names itself two-sided", tst),
                   identical(fld(sprintf("ts|%s", tst))[4], "two-sided"))
    }

    # -- 4. THE ONE-TAILED p IS R'S FIXED-DIRECTION p ----------------------
    # This is what separates the repair from any other change that merely
    # reacts to reversal. min(pGreater, pLess) satisfies section 2 in full
    # and fails every "wrong" row here.
    ot <- list(
        c("welch",    "fwd", t.test(A, B, alternative = "greater")$p.value),
        c("welch",    "rev", t.test(B, A, alternative = "greater")$p.value),
        c("student",  "fwd", t.test(A, B, alternative = "greater", var.equal = TRUE)$p.value),
        c("student",  "rev", t.test(B, A, alternative = "greater", var.equal = TRUE)$p.value),
        c("paired",   "fwd", t.test(PA, PB, paired = TRUE, alternative = "greater")$p.value),
        c("paired",   "rev", t.test(PB, PA, paired = TRUE, alternative = "greater")$p.value),
        c("pearson",  "fwd", cor.test(CX,  CY, alternative = "greater")$p.value),
        c("pearson",  "rev", cor.test(CX, -CY, alternative = "greater")$p.value),
        c("spearman", "fwd", cor.test(rank(CX), rank( CY), alternative = "greater")$p.value),
        c("spearman", "rev", cor.test(rank(CX), rank(-CY), alternative = "greater")$p.value))
    for (row in ot) {
        check("v77",
              sprintf("%s %s: one-tailed p is R's alternative=\"greater\"",
                      row[1], row[2]),
              num(sprintf("ot|%s|%s", row[1], row[2]), 3),
              as.numeric(row[3]), tol = 1e-12)
    }
    # and pLess is R's alternative="less", computed on the other side rather
    # than subtracted from one
    check("v77", "welch pLess is R's alternative=\"less\"",
          num("ot|welch|fwd", 2), t.test(A, B, alternative = "less")$p.value,
          tol = 1e-12)
    check("v77", "pearson pLess is R's alternative=\"less\"",
          num("ot|pearson|fwd", 2), cor.test(CX, CY, alternative = "less")$p.value,
          tol = 1e-12)

    # -- 5. THE WRONG-DIRECTION PERFECT EFFECT -----------------------------
    # p must be 1. Not 0, which is what a magnitude test would say; not
    # undefined, which is what an un-guarded limit would say.
    hugeT  <- num("ext|huge", 1)
    hugeG  <- num("ext|huge", 2)
    hugeL  <- num("ext|huge", 3)
    check_true("v77", sprintf("the huge-separation t is large and negative (%.6g)", hugeT),
               is.finite(hugeT) && hugeT < -1e5)
    check("v77", "wrong-direction perfect effect gives p = 1 EXACTLY",
          hugeG, 1, tol = 0)
    check_true("v77", "and it is a number, not undefined",
               is.finite(hugeG))
    # THE CANCELLATION ARGUMENT, MADE ON A REAL NUMBER. The other tail is
    # ~5.6e-46. Had it been computed as 1 - pGreater it would be exactly 0.
    check_true("v77",
               sprintf("the right-direction tail keeps every digit (%.6g), which 1 - pGreater would have made 0",
                       hugeL),
               is.finite(hugeL) && hugeL > 0 && hugeL < 1e-40)
    check("v77", "and 1 - pGreater really would be exactly zero here",
          1 - hugeG, 0, tol = 0)

    # t = -40 by name, as the assignment asks
    check("v77", "studentQ(-40, 8) is the near-one tail, not one",
          num("ext|t40", 1), 1 - 8.392859439572871e-11, tol = 1e-15)
    check_true("v77", "studentQ(-40, 8) is strictly below 1",
               num("ext|t40", 1) < 1)
    check("v77", "studentQ(+40, 8) keeps its digits",
          num("ext|t40", 2), 8.392859439572871e-11, tol = 1e-20)

    # |r| = 1, both signs
    check("v77", "perfect POSITIVE r: pGreater = 0", num("ext|perfpos", 2), 0, tol = 0)
    check("v77", "perfect POSITIVE r: pLess = 1",    num("ext|perfpos", 3), 1, tol = 0)
    check("v77", "perfect NEGATIVE r: pGreater = 1 (wrong direction, p is ONE)",
          num("ext|perfneg", 2), 1, tol = 0)
    check("v77", "perfect NEGATIVE r: pLess = 0",    num("ext|perfneg", 3), 0, tol = 0)
    check("v77", "perfect NEGATIVE r: .tails = 1 reports p = 1",
          num("ext|perfneg", 4), 1, tol = 0)
    check_true("v77", "perfect NEGATIVE r is still flagged .perfect = 1",
               identical(fld("ext|perfneg")[5], "1"))
    # and the two-sided perfect p is UNCHANGED at 0 -- the shipped behaviour
    check("v77", "perfect r two-sided p is still 0, as it has always been",
          num("ext|perfnegts", 1), 0, tol = 0)
    check("v77", "perfect NEGATIVE rho (Spearman shares the kernel): p = 1",
          num("ext|perfnegsp", 4), 1, tol = 0)

    # -- 6. THE EXPLICIT ENTRY POINTS --------------------------------------
    check("v77", "@emlTTestAlt greater == R greater",
          num("alt|welch|greater", 3), t.test(A, B, alternative = "greater")$p.value,
          tol = 1e-12)
    check("v77", "@emlTTestAlt less == R less",
          num("alt|welch|less", 3), t.test(A, B, alternative = "less")$p.value,
          tol = 1e-12)
    check("v77", "@emlTTestAlt two-sided == R two.sided",
          num("alt|welch|two-sided", 3), t.test(A, B)$p.value, tol = 1e-14)
    check("v77", "@emlTTestPairedAlt less == R paired less",
          num("alt|paired|less", 3),
          t.test(PA, PB, paired = TRUE, alternative = "less")$p.value, tol = 1e-12)
    check("v77", "@emlPearsonCorrelationAlt less == R cor.test less",
          num("alt|pearson|less", 3),
          cor.test(CX, CY, alternative = "less")$p.value, tol = 1e-12)
    check("v77", "@emlSpearmanCorrelationAlt less == R cor.test less on ranks",
          num("alt|spearman|less", 3),
          cor.test(rank(CX), rank(CY), alternative = "less")$p.value, tol = 1e-12)
    for (nm in c("welch", "paired", "pearson", "spearman")) {
        who <- if (nm == "welch") "alt|welch|less" else sprintf("alt|%s|less", nm)
        check_true("v77", sprintf("%s Alt echoes the alternative it was given", nm),
                   identical(fld(who)[4], "less"))
    }

    # AN UNRECOGNISED ALTERNATIVE REFUSES. It must not fall back to
    # two-sided: a silent fallback is this file's own defect in a new coat.
    for (nm in c("welch", "paired", "pearson", "spearman")) {
        f <- fld(sprintf("bad|%s", nm))
        check_true("v77", sprintf("%s Alt refuses an unrecognised alternative", nm),
                   length(f) >= 3 && grepl("two-sided", f[1]) &&
                   grepl("greater", f[1]) && grepl("less", f[1]))
        check_true("v77", sprintf("%s Alt leaves p undefined on refusal, not two-sided", nm),
                   length(f) >= 2 && grepl("undefined", f[2]))
        check_true("v77", sprintf("%s Alt leaves the statistic undefined on refusal", nm),
                   length(f) >= 3 && grepl("undefined", f[3]))
    }

    # -- 7. THE ERROR PATH LEAVES THE NEW OUTPUTS UNSET --------------------
    # New outputs initialised with the old ones, so a caller that reads
    # .pGreater after a refusal gets undefined and not a stale value from the
    # previous call. Praat cannot unset a variable; initialising is the only
    # way this is true.
    ef <- fld("err|badtails")
    check_true("v77", "a bad .tails still reports its error",
               length(ef) >= 1 && grepl("tails must be 1 or 2", ef[1]))
    check_true("v77", "and leaves .pGreater undefined",
               length(ef) >= 2 && grepl("undefined", ef[2]))
    check_true("v77", "and leaves .pLess undefined",
               length(ef) >= 3 && grepl("undefined", ef[3]))
    check_true("v77", "and leaves .alternative$ empty",
               length(ef) >= 4 && identical(ef[4], "[]"))
}
}

if (!exists("EML_SUITE")) {
    eml_report("v77 one-tailed direction: a fixed alternative, and a two-sided p that did not move")
    eml_exit()
}
