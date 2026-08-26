# ============================================================================
# RUN_ME_FIRST.praat -- reads matrix.tsv and runs every one of its 630 cells
# against the EML Stats & Graphs procedures, writing the result in the long
# shared schema to out/praat_results.tsv (source = "praat") and one
# human-readable report per cell_id to out/praat_reports/<cell_id>.txt.
#
# THIS SCRIPT CARRIES NO LIST OF ITS OWN. Every cell it runs comes from
# reading matrix.tsv at run time. Add a row to that file -- no code change
# here -- and this script runs it on the next click of Run. That is proven,
# not just claimed: see PROOF_OF_NO_HARDCODED_LIST.md beside this file for
# the row that was added and removed to demonstrate it.
#
# NOTHING TO INSTALL. The statistics layer travels beside this script as
# eml-lib-flat.praat; there is no plugin in a preferences folder.
#
# PLAIN RELATIVE PATHS THROUGHOUT ("data/...", "out/...", "matrix.tsv",
# "eml-lib-flat.praat"). Praat resolves a relative path in a script against
# THE SCRIPT'S OWN FOLDER, not the working directory it was launched from --
# measured, and depended on here exactly as the smaller predecessor of this
# script depended on it. Keep this folder together: RUN_ME_FIRST.praat,
# eml-lib-flat.praat, matrix.tsv, data/ and out/ all in one place.
#
# TWO PRE-EXISTING LIBRARY DEFECTS, PATCHED IN THIS KIT'S OWN COPY ONLY.
# matrix.tsv's header names D-CORR-1 and D-CORR-2: two correlation cells
# (c0418, c0419) that used to take the WHOLE SCRIPT DOWN on Praat 6.6.30,
# because @emlRunCorrelationAnalysis read .recResult$ before any guard had
# ever set it, and @emlPearsonCorrelation left its numeric outputs unassigned
# on its own error path. Both are now initialised at entry in
# eml-lib-flat.praat, exactly the pattern every sibling orchestrator and
# @emlPearsonCorrelationAlt / @emlSpearmanCorrelation already use -- see the
# "WALKTHROUGH KIT PATCH" comments there. Nothing else in the flat library was
# touched, and the master plugin under plugin_EML_StatsGraphs/ was not
# touched at all: this fix travels only with this kit's own copy. A third,
# related gap -- the same orchestrator does not itself refuse when EVERY
# requested correlation family fails -- is handled here, in this script, not
# in the library: see @emlKitCorrelationRanSomething below.
#
# HOW LONG THIS TAKES. Said again at the end, with the actual figure, but for
# Josh clicking Run without reading the source first: budget low tens of
# seconds on a laptop, not minutes. The dominant cost is loading tables --
# there are only 29 distinct CSVs behind 630 cells, and every cell's table is
# read at most once and cached by dataset name.
# ============================================================================

createFolder: "out"
createFolder: "out/praat_reports"

include eml-lib-flat.praat

if not fileReadable ("matrix.tsv")
    writeInfoLine: "RUN_ME_FIRST.praat cannot find matrix.tsv beside itself."
    appendInfoLine: "Keep the kit folder together and try again."
    exitScript ()
endif
if not folderExists ("data")
    writeInfoLine: "RUN_ME_FIRST.praat cannot find its data/ folder."
    appendInfoLine: "Keep the kit folder together and try again."
    exitScript ()
endif

emlKitStartTime = stopwatch


# ============================================================================
# SECTION 1 -- small string / TSV utilities
# ============================================================================

# ----------------------------------------------------------------------------
# @emlKitLower -- ASCII lowercase. Praat has no built-in lowercase$(); group
# labels and column names in this kit are plain ASCII words, so a manual
# 26-letter lookup is complete for every input this script ever hands it.
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlKitLower: .s$
    .upper$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    .lower$ = "abcdefghijklmnopqrstuvwxyz"
    .result$ = ""
    for .i to length (.s$)
        .ch$ = mid$ (.s$, .i, 1)
        .pos = index (.upper$, .ch$)
        if .pos > 0
            .result$ = .result$ + mid$ (.lower$, .pos, 1)
        else
            .result$ = .result$ + .ch$
        endif
    endfor
endproc

# ----------------------------------------------------------------------------
# @emlKitSlug -- lowercase, spaces to underscores. For pair names and for
# turning a column name into a safe quantity-name fragment.
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlKitSlug: .s$
    @emlKitLower: .s$
    .result$ = replace$ (emlKitLower.result$, " ", "_", 0)
endproc

# ----------------------------------------------------------------------------
# @emlKitPairName -- "labelA__labelB", PAIR NAMING per the shared schema:
# the two labels joined with a double underscore, lowercased, spaces to
# underscores, in the order the caller hands them (which must already be the
# order the matrix's group_order / condition-list column implies).
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlKitPairName: .a$, .b$
    @emlKitSlug: .a$
    .sa$ = emlKitSlug.result$
    @emlKitSlug: .b$
    .sb$ = emlKitSlug.result$
    .result$ = .sa$ + "__" + .sb$
endproc

# ----------------------------------------------------------------------------
# @emlKitSanitizeText -- one line of free text, safe for a TSV cell and for
# an ASCII-only file: tabs and newlines flattened to spaces, then folded to
# ASCII (@emlAsciiFold, eml-core-utilities.praat) so an em dash or curly
# quote in a library error message cannot flip the whole output file to
# UTF-16BE the way CLAUDE.md's rule warns a single non-ASCII byte will.
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlKitSanitizeText: .s$
    .t$ = replace$ (.s$, tab$, " ", 0)
    .t$ = replace$ (.t$, newline$, " ", 0)
    @emlAsciiFold: .t$
    .result$ = emlAsciiFold.result$
endproc

# ----------------------------------------------------------------------------
# Output buffer for out/praat_results.tsv. Built in memory and written once
# at the end -- 630 cells produce several thousand rows, and one write beats
# a few thousand file opens.
# ----------------------------------------------------------------------------
emlKitTSVBuf$ = "cell_id" + tab$ + "quantity" + tab$ + "value" + tab$ + "source" + newline$
emlKitRowCount = 0

# ----------------------------------------------------------------------------
# @emlKitRow -- append one raw row to the output buffer AND to this cell's
# own "what was extracted" log (emlKitQtyLog$, reset per cell and folded into
# that cell's human-readable report -- see @emlKitBeginCell / @emlKitEndCell).
# ----------------------------------------------------------------------------
procedure emlKitRow: .cellId$, .quantity$, .value$, .source$
    emlKitTSVBuf$ = emlKitTSVBuf$ + .cellId$ + tab$ + .quantity$ + tab$
    ... + .value$ + tab$ + .source$ + newline$
    emlKitRowCount = emlKitRowCount + 1
    emlKitQtyLog$ = emlKitQtyLog$ + .quantity$ + tab$ + .value$ + newline$
endproc

# ----------------------------------------------------------------------------
# @emlKitNum -- emit a numeric quantity, RAW AND UNROUNDED (string$ gives full
# IEEE754 precision on this Praat, measured). Silently DOES NOT emit when the
# value is undefined -- "this run did not produce one", the same convention
# the library's own Result Store uses, and not a zero a reader would believe.
# ----------------------------------------------------------------------------
procedure emlKitNum: .cellId$, .quantity$, .value
    if .value <> undefined
        @emlKitRow: .cellId$, .quantity$, string$ (.value), "praat"
    else
        # AN UNDEFINED VALUE IS NOT A REASON TO WRITE NOTHING. Dropping it
        # leaves the quantity looking like one this runner never attempted,
        # which in the join is indistinguishable from a coverage hole -- and
        # that is exactly how @emlRunPairwiseAnalysis's .stN went unnoticed:
        # it is listed in that procedure's own Outputs header, initialised to
        # undefined, and never assigned. The marker makes the difference
        # between "computed, came out undefined" and "never computed" visible
        # in the results table itself.
        @emlKitRow: .cellId$, .quantity$ + "_undefined", "1", "praat"
    endif
endproc

# ----------------------------------------------------------------------------
# @emlKitText -- emit a text-valued quantity (refuse_reason, skip_reason).
# ----------------------------------------------------------------------------
procedure emlKitText: .cellId$, .quantity$, .text$
    @emlKitSanitizeText: .text$
    @emlKitRow: .cellId$, .quantity$, emlKitSanitizeText.result$, "praat"
endproc

# ----------------------------------------------------------------------------
# @emlKitRefuse / @emlKitSkip -- A REFUSAL IS A ROW, A SKIP IS A ROW. Never a
# blank, never a crash, never a silent fallback.
# ----------------------------------------------------------------------------
procedure emlKitRefuse: .cellId$, .reason$
    @emlKitRow: .cellId$, "refused", "1", "praat"
    @emlKitText: .cellId$, "refuse_reason", .reason$
endproc

procedure emlKitSkip: .cellId$, .reason$
    @emlKitRow: .cellId$, "skipped", "1", "praat"
    @emlKitText: .cellId$, "skip_reason", .reason$
endproc

# ----------------------------------------------------------------------------
# @emlKitSplit17 -- split one matrix.tsv line into its 17 tab-separated
# columns (cell_id, lane, procedure, dataset, col_a, col_b, col_c, test,
# posthoc, adjust, equal_var, group_order, conf, correction, prereq, expect,
# note), header order verbatim from matrix.tsv. Output: .f$[1..17].
# ----------------------------------------------------------------------------
procedure emlKitSplit17: .line$
    .rest$ = .line$
    for .c from 1 to 16
        .tPos = index (.rest$, tab$)
        if .tPos = 0
            .f$ [.c] = .rest$
            .rest$ = ""
        else
            .f$ [.c] = left$ (.rest$, .tPos - 1)
            .rest$ = mid$ (.rest$, .tPos + 1, length (.rest$) - .tPos)
        endif
    endfor
    .f$ [17] = .rest$
endproc

# ----------------------------------------------------------------------------
# @emlKitSetGroupOrder -- group_order -> emlGroupSortAlphabetical (declared in
# stats/eml-extract.praat; 0 = discovery, the library default, 1 = alpha).
# GROUP ORDER IS RESULT-AFFECTING (matrix.tsv's own header measurement: the
# same t flips sign under the two orders), so this is set EVERY row, from
# that row's own group_order field, defaulting to discovery when the field is
# blank -- never left over from the previous cell.
# ----------------------------------------------------------------------------
procedure emlKitSetGroupOrder: .go$
    if .go$ = "alphabetical"
        emlGroupSortAlphabetical = 1
    else
        emlGroupSortAlphabetical = 0
    endif
endproc

# ----------------------------------------------------------------------------
# Table cache -- 29 distinct dataset stems behind 630 cells. Each is read
# from data/<name>.csv at most once and reused by object ID thereafter.
# ----------------------------------------------------------------------------
emlKitCacheN = 0
procedure emlKitGetTable: .dataset$
    .found = 0
    .i = 1
    while .i <= emlKitCacheN and .found = 0
        if emlKitCacheName$ [.i] = .dataset$
            .tableId = emlKitCacheId [.i]
            .found = 1
        endif
        .i = .i + 1
    endwhile
    if .found = 0
        .tableId = Read Table from comma-separated file: "data/" + .dataset$ + ".csv"
        emlKitCacheN = emlKitCacheN + 1
        emlKitCacheName$ [emlKitCacheN] = .dataset$
        emlKitCacheId [emlKitCacheN] = .tableId
    endif
endproc

# ----------------------------------------------------------------------------
# @emlKitStripQuotes -- every CSV under data/ for the SURVEY lane has a
# quoted header row ("case","x","n","conf", and so on); the analysis lane's
# CSVs do not. Measured on this Praat: "Read Table from comma-separated
# file:" keeps a quoted header's quote characters as PART of the column
# name ("Get column label:" returns the six characters "case", literally),
# while a quoted DATA cell has its quotes stripped normally. So the column
# name has to be looked up by its raw (quoted) form, and only the STRIPPED
# form belongs in a quantity name or a case-label comparison.
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlKitStripQuotes: .s$
    .result$ = .s$
    .q$ = """"
    if length (.result$) >= 2
        if left$ (.result$, 1) = .q$
            if right$ (.result$, 1) = .q$
                .result$ = mid$ (.result$, 2, length (.result$) - 2)
            endif
        endif
    endif
endproc

# ----------------------------------------------------------------------------
# @emlKitFindColRaw -- find a Table column by its NAME AFTER QUOTE-STRIPPING
# (so "case" finds a column literally named "case" whether the CSV's header
# was quoted or not) and return the RAW label Table commands need to address
# it. .rawName$ = "" when no column matches.
# ----------------------------------------------------------------------------
procedure emlKitFindColRaw: .tableId, .wantName$
    selectObject: .tableId
    .nc = Get number of columns
    .rawName$ = ""
    for .j from 1 to .nc
        .lbl$ = Get column label: .j
        @emlKitStripQuotes: .lbl$
        if emlKitStripQuotes.result$ = .wantName$
            .rawName$ = .lbl$
        endif
    endfor
endproc

# ----------------------------------------------------------------------------
# @emlKitTableToMatrix -- read every cell of a Table into a numeric matrix,
# through the SAME cell reader the library's own row-wise extractors use
# (@eml_openColumn / @eml_readCell, eml-extract.praat), so "NA" and any other
# unreadable cell becomes `undefined` exactly as it would inside the library,
# not by a second, independently-invented parsing rule.
# .colLabel$ holds the raw (possibly quoted) label, for feeding back into a
# Table command; .colLabelClean$ holds it quote-stripped, for a quantity name.
# Output: .m## (.nRows x .nCols), .nRows, .nCols
# ----------------------------------------------------------------------------
procedure emlKitTableToMatrix: .tableId
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns
    .m## = zero## (.nRows, .nCols)
    for .j from 1 to .nCols
        .colName$ = Get column label: .j
        .colLabel$ [.j] = .colName$
        @emlKitStripQuotes: .colName$
        .colLabelClean$ [.j] = emlKitStripQuotes.result$
        @eml_openColumn: .tableId, .colName$
        .clean = eml_openColumn.clean
        for .i from 1 to .nRows
            @eml_readCell: .tableId, .i, .colName$, .clean
            .m## [.i, .j] = eml_readCell.value
        endfor
    endfor
endproc


# ============================================================================
# SECTION 2 -- per-cell report bookkeeping
# ============================================================================

procedure emlKitBeginCell: .cellId$
    clearinfo
    emlKitQtyLog$ = ""
endproc

# ----------------------------------------------------------------------------
# @emlKitEndCell -- write out/praat_reports/<cell_id>.txt: this script's own
# header (every column of the matrix row, so the report is self-contained),
# then whatever the library printed to the Info window for this cell (APA
# formatting intact -- that is what a human wants when a row disagrees), then
# the raw quantities this script actually extracted and emitted.
# ----------------------------------------------------------------------------
procedure emlKitEndCell: .cellId$, .lane$, .proc$, .dataset$, .colA$, .colB$,
    ... .colC$, .test$, .posthoc$, .adjust$, .equalVar$, .groupOrder$,
    ... .conf$, .correction$, .prereq$, .expect$, .note$, .outcome$

    .rep$ = "=== " + .cellId$ + " ===" + newline$
    .rep$ = .rep$ + "lane: " + .lane$ + newline$
    .rep$ = .rep$ + "procedure: " + .proc$ + newline$
    .rep$ = .rep$ + "dataset: " + .dataset$ + newline$
    .rep$ = .rep$ + "col_a=" + .colA$ + "  col_b=" + .colB$
    ... + "  col_c=" + .colC$ + newline$
    .rep$ = .rep$ + "test=" + .test$ + "  posthoc=" + .posthoc$
    ... + "  adjust=" + .adjust$ + "  equal_var=" + .equalVar$ + newline$
    .rep$ = .rep$ + "group_order=" + .groupOrder$ + "  conf=" + .conf$
    ... + "  correction=" + .correction$ + newline$
    if .prereq$ <> ""
        .rep$ = .rep$ + "prereq: " + .prereq$ + newline$
    endif
    .rep$ = .rep$ + "expect: " + .expect$ + newline$
    if .note$ <> ""
        @emlKitSanitizeText: .note$
        .rep$ = .rep$ + "note: " + emlKitSanitizeText.result$ + newline$
    endif
    .rep$ = .rep$ + "outcome: " + .outcome$ + newline$
    .rep$ = .rep$ + newline$
    .rep$ = .rep$ + "--- library report (as printed to the Info window) ---"
    ... + newline$
    .rep$ = .rep$ + info$ () + newline$
    .rep$ = .rep$ + "--- quantities extracted (raw, unrounded) ---" + newline$
    if emlKitQtyLog$ = ""
        .rep$ = .rep$ + "(none)" + newline$
    else
        .rep$ = .rep$ + emlKitQtyLog$
    endif
    @emlKitSanitizeText: .rep$
    ; Sanitizing the WHOLE report would collapse its internal newlines, so
    ; only fold to ASCII here and keep the original's line breaks.
    @emlAsciiFold: .rep$
    writeFile: "out/praat_reports/" + .cellId$ + ".txt", emlAsciiFold.result$
endproc


# ============================================================================
# SECTION 3 -- prereq execution
# ============================================================================
# Format "procName:arg1,arg2" (matrix.tsv header). Only one prereq shape is
# declared anywhere in the matrix -- @emlRunRegressionAnalysis, called with
# (depCol$, predCol$) immediately before @emlRunGroupedRegression reads
# emlLinearRegression.* from its overall fit -- so that is the one this
# recognises; an unrecognised prereq refuses loudly rather than silently
# skipping the call it was supposed to make.
# ----------------------------------------------------------------------------
procedure emlKitRunPrereq: .tableId, .prereq$
    .ok = 1
    .colonPos = index (.prereq$, ":")
    .proc$ = left$ (.prereq$, .colonPos - 1)
    .args$ = mid$ (.prereq$, .colonPos + 1,
    ... length (.prereq$) - .colonPos)
    .commaPos = index (.args$, ",")
    .arg1$ = left$ (.args$, .commaPos - 1)
    .arg2$ = mid$ (.args$, .commaPos + 1, length (.args$) - .commaPos)
    if .proc$ = "emlRunRegressionAnalysis"
        @emlRunRegressionAnalysis: .tableId, .arg1$, .arg2$
    else
        .ok = 0
    endif
endproc


# ============================================================================
# SECTION 4 -- read matrix.tsv and dispatch every data row
# ============================================================================

emlKitNCells = 0
emlKitNRefused = 0
emlKitNOk = 0
emlKitNMismatch = 0
emlKitMismatchList$ = ""
emlKitHeaderSeen = 0

emlKitRemaining$ = readFile$ ("matrix.tsv") + newline$

while length (emlKitRemaining$) > 0
    emlKitNlPos = index (emlKitRemaining$, newline$)
    emlKitLine$ = left$ (emlKitRemaining$, emlKitNlPos - 1)
    emlKitRemaining$ = mid$ (emlKitRemaining$, emlKitNlPos + 1,
    ... length (emlKitRemaining$) - emlKitNlPos)

    if length (emlKitLine$) = 0
        # blank line: nothing to do
    elsif left$ (emlKitLine$, 1) = "#"
        # comment line: nothing to do
    elsif emlKitHeaderSeen = 0
        if left$ (emlKitLine$, 7) = "cell_id"
            emlKitHeaderSeen = 1
        endif
    else
        @emlKitSplit17: emlKitLine$
        @emlKitProcessRow:
        ... emlKitSplit17.f$[1], emlKitSplit17.f$[2], emlKitSplit17.f$[3],
        ... emlKitSplit17.f$[4], emlKitSplit17.f$[5], emlKitSplit17.f$[6],
        ... emlKitSplit17.f$[7], emlKitSplit17.f$[8], emlKitSplit17.f$[9],
        ... emlKitSplit17.f$[10], emlKitSplit17.f$[11], emlKitSplit17.f$[12],
        ... emlKitSplit17.f$[13], emlKitSplit17.f$[14], emlKitSplit17.f$[15],
        ... emlKitSplit17.f$[16], emlKitSplit17.f$[17]
    endif
endwhile


# ============================================================================
# SECTION 5 -- @emlKitProcessRow: one matrix.tsv data row, start to finish
# ============================================================================
procedure emlKitProcessRow: .cellId$, .lane$, .proc$, .dataset$, .colA$,
    ... .colB$, .colC$, .test$, .posthoc$, .adjust$, .equalVar$,
    ... .groupOrder$, .conf$, .correction$, .prereq$, .expect$, .note$

    emlKitNCells = emlKitNCells + 1
    @emlKitBeginCell: .cellId$

    @emlKitSetGroupOrder: .groupOrder$

    .refused = 0
    .refuseReason$ = ""

    if .lane$ = "survey"
        @emlKitGetTable: .dataset$
        .tableId = emlKitGetTable.tableId
        @emlKitDispatchSurvey: .cellId$, .proc$, .tableId, .colA$, .colB$,
        ... .colC$, .conf$, .correction$
        .refused = emlKitDispatchSurvey.refused
        .refuseReason$ = emlKitDispatchSurvey.refuseReason$
    else
        @emlKitGetTable: .dataset$
        .tableId = emlKitGetTable.tableId

        if .prereq$ <> ""
            @emlKitRunPrereq: .tableId, .prereq$
            if emlKitRunPrereq.ok = 0
                .refused = 1
                .refuseReason$ = "RUNNER DEFECT: unrecognised prereq """
                ... + .prereq$ + """ -- add it to @emlKitRunPrereq."
            endif
        endif

        if .refused = 0
            @emlKitDispatchAnalysis: .cellId$, .proc$, .tableId, .colA$,
            ... .colB$, .colC$, .test$, .posthoc$, .adjust$, .equalVar$,
            ... .conf$, .correction$
            .refused = emlKitDispatchAnalysis.refused
            .refuseReason$ = emlKitDispatchAnalysis.refuseReason$
        endif
    endif

    if .refused = 1
        @emlKitRefuse: .cellId$, .refuseReason$
        emlKitNRefused = emlKitNRefused + 1
        .outcome$ = "refused"
    else
        emlKitNOk = emlKitNOk + 1
        .outcome$ = "ok"
    endif

    if .expect$ = "refuse" and .refused = 0
        emlKitNMismatch = emlKitNMismatch + 1
        emlKitMismatchList$ = emlKitMismatchList$ + .cellId$
        ... + " (expected refuse, ran ok)" + newline$
        .outcome$ = .outcome$ + "  *** MISMATCH: matrix.tsv expects refuse ***"
    elsif .expect$ = "ok" and .refused = 1
        emlKitNMismatch = emlKitNMismatch + 1
        emlKitMismatchList$ = emlKitMismatchList$ + .cellId$
        ... + " (expected ok, refused: " + .refuseReason$ + ")" + newline$
        .outcome$ = .outcome$ + "  *** MISMATCH: matrix.tsv expects ok ***"
    endif

    @emlKitEndCell: .cellId$, .lane$, .proc$, .dataset$, .colA$, .colB$,
    ... .colC$, .test$, .posthoc$, .adjust$, .equalVar$, .groupOrder$,
    ... .conf$, .correction$, .prereq$, .expect$, .note$, .outcome$
endproc


# ============================================================================
# SECTION 6 -- shared post-hoc pairwise matrix emitter
# ============================================================================
# Used by ANOVA (Tukey / the always-computed pairwise Cohen's d fallback),
# Kruskal-Wallis (Dunn / the always-computed pairwise rank-biserial r
# fallback) and Pairwise (Welch t / Student t / Wilcoxon / Scheffe).
# PAIR NAMING per the shared schema: the two group labels in the order
# emlPublishInLabel$ holds them -- which IS the group_order-implied order,
# because @emlStoreKeyTake / @emlCountGroups fixed it before any contrast was
# formed -- joined "labelA__labelB", first-minus-second. Every matrix this
# library builds is already written [i,j] = i-vs-j, [j,i] = -(i-vs-j) (Tukey
# meanDiff##, the Cohen's-d and rank-biserial-r fallbacks, Dunn's z, Scheffe's
# diffMatrix##), so reading [i,j] for i<j needs no re-orientation here -- that
# bookkeeping already happened at the point each matrix was built.
#
# NO CONFIDENCE INTERVAL IS EMITTED for any pairwise comparison. None of
# @emlTukeyHSD / @emlDunnTest / @emlPairwiseT / @emlPairwiseWilcoxon /
# @emlScheffe expose one (each gives a statistic, a p and an effect size, not
# a bound) and deriving one from qCritical or a pairwise SE this script does
# not itself have would be a second, independently-invented computation --
# exactly what this kit exists to avoid. See the final report: this is a
# known, reported gap, not a silent omission.
# ----------------------------------------------------------------------------
procedure emlKitEmitPosthocPairs: .cellId$, .nGroups, .statName$, .effName$,
    ... .hasDiff, .hasEff, .hasStat, .rawSource$

    .pairIdx = 0
    for .i from 1 to .nGroups - 1
        for .j from .i + 1 to .nGroups
            .pairIdx = .pairIdx + 1
            @emlKitPairName: emlPublishInLabel$ [.i], emlPublishInLabel$ [.j]
            .pn$ = emlKitPairName.result$

            @emlKitNum: .cellId$, "posthoc_" + .pn$ + "_padj",
            ... emlKitCurPMat## [.i, .j]

            if .hasDiff = 1
                @emlKitNum: .cellId$, "posthoc_" + .pn$ + "_diff",
                ... emlKitCurDiffMat## [.i, .j]
            endif
            if .hasStat = 1
                @emlKitNum: .cellId$, "posthoc_" + .pn$ + "_" + .statName$,
                ... emlKitCurStatMat## [.i, .j]
            endif
            if .hasEff = 1
                @emlKitNum: .cellId$, "posthoc_" + .pn$ + "_" + .effName$,
                ... emlKitCurEffMat## [.i, .j]
            endif

            if .rawSource$ = "dunn"
                @emlKitNum: .cellId$, "posthoc_" + .pn$ + "_p",
                ... emlDunnTest.rawP# [.pairIdx]
            elsif .rawSource$ = "pairwiseT"
                @emlKitNum: .cellId$, "posthoc_" + .pn$ + "_p",
                ... emlPairwiseT.rawP# [.pairIdx]
            elsif .rawSource$ = "pairwiseWilcoxon"
                @emlKitNum: .cellId$, "posthoc_" + .pn$ + "_p",
                ... emlPairwiseWilcoxon.rawP# [.pairIdx]
            endif
        endfor
    endfor
endproc


# ============================================================================
# SECTION 7 -- @emlKitDispatchAnalysis: the 13 analysis-lane procedures
# ============================================================================
# Output: .refused, .refuseReason$
# ============================================================================
procedure emlKitDispatchAnalysis: .cellId$, .proc$, .tableId, .colA$, .colB$,
    ... .colC$, .test$, .posthoc$, .adjust$, .equalVar$, .conf$, .correction$

    .refused = 0
    .refuseReason$ = ""

    if .proc$ = "emlRunTwoGroupAnalysis"
        # --- 1. TWO INDEPENDENT GROUPS -----------------------------------
        .equalVarN = number (.equalVar$)
        @emlRunTwoGroupAnalysis: .tableId, .colA$, .colB$, .test$, .equalVarN
        if emlRunTwoGroupAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunTwoGroupAnalysis.error$
        else
            @emlKitNum: .cellId$, "n_group1", emlRunTwoGroupAnalysis.n1
            @emlKitNum: .cellId$, "n_group2", emlRunTwoGroupAnalysis.n2
            @emlKitNum: .cellId$, "n", emlRunTwoGroupAnalysis.n1
            ... + emlRunTwoGroupAnalysis.n2
            @emlKitNum: .cellId$, "mean_group1", emlRunTwoGroupAnalysis.mean1
            @emlKitNum: .cellId$, "mean_group2", emlRunTwoGroupAnalysis.mean2
            @emlKitNum: .cellId$, "sd_group1", emlRunTwoGroupAnalysis.sd1
            @emlKitNum: .cellId$, "sd_group2", emlRunTwoGroupAnalysis.sd2
            @emlKitNum: .cellId$, "median_group1",
            ... emlRunTwoGroupAnalysis.median1
            @emlKitNum: .cellId$, "median_group2",
            ... emlRunTwoGroupAnalysis.median2
            @emlKitNum: .cellId$, "mean_diff", emlRunTwoGroupAnalysis.mean1
            ... - emlRunTwoGroupAnalysis.mean2

            .parRan = (emlRunTwoGroupAnalysis.stOmniLabel$ = "t")
            .nonRan = (emlRunTwoGroupAnalysis.stOmniLabel$ = "U")
            ... or (emlRunTwoGroupAnalysis.stSecLabel$ = "U")

            if .parRan
                @emlKitNum: .cellId$, "t", emlRunTwoGroupAnalysis.stOmni
                @emlKitNum: .cellId$, "df", emlRunTwoGroupAnalysis.stDf1
                @emlKitNum: .cellId$, "p", emlRunTwoGroupAnalysis.stP
                @emlKitNum: .cellId$, "cohens_d", emlCohenD.d
                @emlKitNum: .cellId$, "hedges_g", emlCohenD.g
            endif
            if .nonRan
                @emlKitNum: .cellId$, "u1", emlMannWhitneyU.u1
                @emlKitNum: .cellId$, "u2", emlMannWhitneyU.u2
                @emlKitNum: .cellId$, "rank_biserial", emlRankBiserialR.r
                if .parRan
                    # "p_secondary" names an argument position, not a test.
                    @emlKitNum: .cellId$, "mw_p",
                    ... emlRunTwoGroupAnalysis.stSecP
                else
                    @emlKitNum: .cellId$, "p", emlRunTwoGroupAnalysis.stP
                endif
            endif
        endif

    elsif .proc$ = "emlRunAnovaAnalysis"
        # --- 2. ONE-WAY ANOVA (+ TUKEY) ----------------------------------
        .doTukey = number (.posthoc$)
        @emlRunAnovaAnalysis: .tableId, .colA$, .colB$, .doTukey
        if emlRunAnovaAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunAnovaAnalysis.error$
        else
            @emlKitNum: .cellId$, "f", emlRunAnovaAnalysis.stOmni
            @emlKitNum: .cellId$, "df_between", emlRunAnovaAnalysis.stDf1
            @emlKitNum: .cellId$, "df_within", emlRunAnovaAnalysis.stDf2
            @emlKitNum: .cellId$, "p", emlRunAnovaAnalysis.stP
            @emlKitNum: .cellId$, "eta_squared", emlRunAnovaAnalysis.stEff
            @emlKitNum: .cellId$, "n", emlRunAnovaAnalysis.stN
            @emlKitNum: .cellId$, "ss_between", emlOneWayAnova.ssBetween
            @emlKitNum: .cellId$, "ss_within", emlOneWayAnova.ssWithin
            @emlKitNum: .cellId$, "ss_total", emlOneWayAnova.ssTotal
            @emlKitNum: .cellId$, "ms_between", emlOneWayAnova.msBetween
            @emlKitNum: .cellId$, "ms_within", emlOneWayAnova.msWithin

            # The pairwise Cohen's d matrix is ALWAYS populated (Tukey's own
            # when doTukey=1, the orchestrator's own fallback loop when
            # doTukey=0 -- see @emlRunAnovaAnalysis), so it is always emitted.
            emlKitCurEffMat## = emlRunAnovaAnalysis.stEffMat##
            if .doTukey = 1
                emlKitCurPMat## = emlRunAnovaAnalysis.stPMat##
                emlKitCurStatMat## = emlRunAnovaAnalysis.stStatMat##
                emlKitCurDiffMat## = emlRunAnovaAnalysis.stDiffMat##
                @emlKitEmitPosthocPairs: .cellId$,
                ... emlRunAnovaAnalysis.stNGroups, "q", "cohens_d", 1, 1, 1, ""
            else
                # No Tukey p/q/diff this row -- only the always-on Cohen's d.
                .nG = emlRunAnovaAnalysis.stNGroups
                for .pi from 1 to .nG - 1
                    for .pj from .pi + 1 to .nG
                        @emlKitPairName: emlPublishInLabel$ [.pi],
                        ... emlPublishInLabel$ [.pj]
                        @emlKitNum: .cellId$,
                        ... "posthoc_" + emlKitPairName.result$ + "_cohens_d",
                        ... emlRunAnovaAnalysis.stEffMat## [.pi, .pj]
                    endfor
                endfor
            endif
        endif

    elsif .proc$ = "emlRunKWAnalysis"
        # --- 3. KRUSKAL-WALLIS (+ DUNN) ----------------------------------
        .doDunn = number (.posthoc$)
        @emlRunKWAnalysis: .tableId, .colA$, .colB$, .doDunn, .adjust$
        if emlRunKWAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunKWAnalysis.error$
        else
            @emlKitNum: .cellId$, "h", emlRunKWAnalysis.stOmni
            @emlKitNum: .cellId$, "df", emlRunKWAnalysis.stDf1
            @emlKitNum: .cellId$, "p", emlRunKWAnalysis.stP
            @emlKitNum: .cellId$, "epsilon_squared", emlRunKWAnalysis.stEff
            @emlKitNum: .cellId$, "n", emlRunKWAnalysis.stN

            emlKitCurEffMat## = emlRunKWAnalysis.stEffMat##
            if emlRunKWAnalysis.stDunnRan = 1
                emlKitCurPMat## = emlRunKWAnalysis.stPMat##
                emlKitCurStatMat## = emlRunKWAnalysis.stStatMat##
                @emlKitEmitPosthocPairs: .cellId$,
                ... emlRunKWAnalysis.stNGroups, "z", "rank_biserial", 0, 1, 1,
                ... "dunn"
            endif
            # WITH THE POST HOC OFF, NO POST-HOC ROW IS WRITTEN. The library
            # fills its pairwise effect-size matrix whether or not Dunn ran,
            # and this used to emit posthoc_<pair>_rank_biserial from it on
            # cells the declaration marks posthoc=0 -- reporting a pairwise
            # comparison nobody asked for, on exactly the rows whose own note
            # says the adjustment is unread because the post hoc is off.
        endif

    elsif .proc$ = "emlRunPairwiseAnalysis"
        # --- 4. PAIRWISE COMPARISONS -------------------------------------
        @emlRunPairwiseAnalysis: .tableId, .colA$, .colB$, .test$, .adjust$
        if emlRunPairwiseAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunPairwiseAnalysis.error$
        else
            # "n" IS THE SAMPLE SIZE. This emitted .stNGroups -- the number
            # of GROUPS -- under the canonical name "n", so every pairwise
            # cell reported n = 3 where the sample was 45. The procedure
            # exposes both; the group count belongs under "k".
            @emlKitNum: .cellId$, "n", emlRunPairwiseAnalysis.stN
            @emlKitNum: .cellId$, "k", emlRunPairwiseAnalysis.stNGroups
            .nG = emlRunPairwiseAnalysis.stNGroups
            emlKitCurPMat## = emlRunPairwiseAnalysis.stPMat##
            emlKitCurStatMat## = emlRunPairwiseAnalysis.stStatMat##
            emlKitCurDiffMat## = emlRunPairwiseAnalysis.stDiffMat##
            emlKitCurEffMat## = emlRunPairwiseAnalysis.stEffMat##
            if .test$ = "welch" or .test$ = "student"
                @emlKitEmitPosthocPairs: .cellId$, .nG, "t", "cohens_d",
                ... 0, 1, 1, "pairwiseT"
                # @emlPairwiseT carries .dfMatrix## beside .tMatrix## so a
                # report can print t(df); it was computed and then dropped.
                for .pi from 1 to .nG - 1
                    for .pj from .pi + 1 to .nG
                        @emlKitPairName: emlPublishInLabel$ [.pi],
                        ... emlPublishInLabel$ [.pj]
                        @emlKitNum: .cellId$,
                        ... "posthoc_" + emlKitPairName.result$ + "_df",
                        ... emlPairwiseT.dfMatrix## [.pi, .pj]
                    endfor
                endfor
            elsif .test$ = "wilcoxon"
                @emlKitEmitPosthocPairs: .cellId$, .nG, "u", "rank_biserial",
                ... 0, 1, 1, "pairwiseWilcoxon"
            elsif .test$ = "scheffe"
                @emlKitEmitPosthocPairs: .cellId$, .nG, "f", "", 1, 0, 1, ""
            endif
        endif

    elsif .proc$ = "emlRunTwoWayAnalysis"
        # --- 5. TWO-WAY ANOVA --------------------------------------------
        @emlRunTwoWayAnalysis: .tableId, .colA$, .colB$, .colC$
        if emlRunTwoWayAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunTwoWayAnalysis.error$
        else
            @emlKitSlug: .colB$
            .f1$ = emlKitSlug.result$
            @emlKitSlug: .colC$
            .f2$ = emlKitSlug.result$
            # Sidecars so the factor-keyed quantities above are readable
            # without knowing which column the declaration passed as col_b.
            @emlKitText: .cellId$, "factor1_name", .f1$
            @emlKitText: .cellId$, "factor2_name", .f2$
            @emlKitNum: .cellId$, "n", emlTwoWayAnova.nObs
            @emlKitNum: .cellId$, "df_within", emlTwoWayAnova.dfError
            @emlKitNum: .cellId$, "ms_within", emlTwoWayAnova.msError
            @emlKitNum: .cellId$, "ss_within", emlTwoWayAnova.ssError
            @emlKitNum: .cellId$, "ss_total", emlTwoWayAnova.ssTotal
            @emlKitNum: .cellId$, "df_total", emlTwoWayAnova.dfTotal

            @emlKitNum: .cellId$, .f1$ + "_f", emlTwoWayAnova.fA
            @emlKitNum: .cellId$, .f1$ + "_df", emlTwoWayAnova.dfA
            @emlKitNum: .cellId$, .f1$ + "_p", emlTwoWayAnova.pA
            @emlKitNum: .cellId$, .f1$ + "_ss", emlTwoWayAnova.ssA
            @emlKitNum: .cellId$, .f1$ + "_ms", emlTwoWayAnova.msA
            @emlKitNum: .cellId$, .f1$ + "_partial_eta_squared",
            ... emlTwoWayAnova.partialEtaSqA

            @emlKitNum: .cellId$, .f2$ + "_f", emlTwoWayAnova.fB
            @emlKitNum: .cellId$, .f2$ + "_df", emlTwoWayAnova.dfB
            @emlKitNum: .cellId$, .f2$ + "_p", emlTwoWayAnova.pB
            @emlKitNum: .cellId$, .f2$ + "_ss", emlTwoWayAnova.ssB
            @emlKitNum: .cellId$, .f2$ + "_ms", emlTwoWayAnova.msB
            @emlKitNum: .cellId$, .f2$ + "_partial_eta_squared",
            ... emlTwoWayAnova.partialEtaSqB

            @emlKitNum: .cellId$, .f1$ + "__" + .f2$ + "_f",
            ... emlTwoWayAnova.fAB
            @emlKitNum: .cellId$, .f1$ + "__" + .f2$ + "_df",
            ... emlTwoWayAnova.dfAB
            @emlKitNum: .cellId$, .f1$ + "__" + .f2$ + "_p",
            ... emlTwoWayAnova.pAB
            @emlKitNum: .cellId$, .f1$ + "__" + .f2$ + "_ss",
            ... emlTwoWayAnova.ssAB
            @emlKitNum: .cellId$, .f1$ + "__" + .f2$ + "_ms",
            ... emlTwoWayAnova.msAB
            @emlKitNum: .cellId$, .f1$ + "__" + .f2$
            ... + "_partial_eta_squared", emlTwoWayAnova.partialEtaSqAB
        endif

    elsif .proc$ = "emlRunPairedAnalysis"
        # --- 6. PAIRED COMPARISON ----------------------------------------
        @emlRunPairedAnalysis: .tableId, .colA$, .colB$, .test$
        if emlRunPairedAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunPairedAnalysis.error$
        else
            @emlKitNum: .cellId$, "n", emlRunPairedAnalysis.n
            @emlKitNum: .cellId$, "mean_group1", emlRunPairedAnalysis.mean1
            @emlKitNum: .cellId$, "mean_group2", emlRunPairedAnalysis.mean2
            @emlKitNum: .cellId$, "sd_group1", emlRunPairedAnalysis.sd1
            @emlKitNum: .cellId$, "sd_group2", emlRunPairedAnalysis.sd2
            @emlKitNum: .cellId$, "median_group1",
            ... emlRunPairedAnalysis.median1
            @emlKitNum: .cellId$, "median_group2",
            ... emlRunPairedAnalysis.median2
            @emlKitNum: .cellId$, "mean_diff", emlRunPairedAnalysis.mean1
            ... - emlRunPairedAnalysis.mean2

            .parOK = (emlRunPairedAnalysis.didParametric = 1)
            ... and (emlRunPairedAnalysis.failParametric$ = "")
            .nonOK = (emlRunPairedAnalysis.didNonparametric = 1)
            ... and (emlRunPairedAnalysis.failNonparametric$ = "")

            if .parOK
                @emlKitNum: .cellId$, "t", emlTTestPaired.t
                @emlKitNum: .cellId$, "df", emlTTestPaired.df
                @emlKitNum: .cellId$, "p", emlTTestPaired.p
                @emlKitNum: .cellId$, "cohens_dz", emlCohenDz.dz
            endif
            if .nonOK
                @emlKitNum: .cellId$, "w_statistic",
                ... emlWilcoxonSignedRank.tPlus
                @emlKitNum: .cellId$, "rank_biserial", emlMatchedPairsR.r
                if .parOK
                    @emlKitNum: .cellId$, "wilcoxon_p",
                    ... emlWilcoxonSignedRank.p
                else
                    @emlKitNum: .cellId$, "p", emlWilcoxonSignedRank.p
                endif
            endif
        endif

    elsif .proc$ = "emlRunCorrelationAnalysis"
        # --- 7. CORRELATION -----------------------------------------------
        @emlRunCorrelationAnalysis: .tableId, .colA$, .colB$, .test$
        @emlKitCorrelationRanSomething: .test$
        if emlRunCorrelationAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunCorrelationAnalysis.error$
        elsif emlKitCorrelationRanSomething.ranSomething = 0
            .refused = 1
            .refuseReason$ = emlKitCorrelationRanSomething.reason$
        else
            @emlKitNum: .cellId$, "n", emlRunCorrelationAnalysis.n
            if .test$ = "pearson" or .test$ = "both"
                if emlRunCorrelationAnalysis.pearErr$ = ""
                    @emlKitNum: .cellId$, "r", emlRunCorrelationAnalysis.pearR
                    @emlKitNum: .cellId$, "t", emlRunCorrelationAnalysis.pearT
                    @emlKitNum: .cellId$, "df",
                    ... emlRunCorrelationAnalysis.pearDf
                    @emlKitNum: .cellId$, "p", emlRunCorrelationAnalysis.pearP
                endif
            endif
            if .test$ = "spearman" or .test$ = "both"
                if emlRunCorrelationAnalysis.spearErr$ = ""
                    @emlKitNum: .cellId$, "rho",
                    ... emlRunCorrelationAnalysis.spearRho
                    @emlKitNum: .cellId$, "spearman_t",
                    ... emlRunCorrelationAnalysis.spearT
                    @emlKitNum: .cellId$, "spearman_df",
                    ... emlRunCorrelationAnalysis.spearDf
                    # THIS IS THE ASYMPTOTIC p, and the name now says so.
                    # The library derives Spearman's p from a t on n-2 df;
                    # R's cor.test returns the EXACT permutation p for small
                    # n without ties. They are different p-values for the
                    # same null (most visibly at rho = 1, where the exact p
                    # is 2/n! and the approximation collapses to ~0), so
                    # they must not share the bare name "spearman_p".
                    @emlKitNum: .cellId$, "spearman_p_asymptotic",
                    ... emlRunCorrelationAnalysis.spearP
                    if .test$ = "spearman"
                        @emlKitNum: .cellId$, "p",
                        ... emlRunCorrelationAnalysis.spearP
                    endif
                endif
            endif
        endif

    elsif .proc$ = "emlRunDescriptiveAnalysis"
        # --- 8. DESCRIPTIVE STATISTICS ------------------------------------
        @emlRunDescriptiveAnalysis: .tableId, .colA$
        if emlRunDescriptiveAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunDescriptiveAnalysis.error$
        else
            @emlKitNum: .cellId$, "n", emlDescribe.n
            @emlKitNum: .cellId$, "mean", emlDescribe.mean
            @emlKitNum: .cellId$, "sd", emlDescribe.sd
            @emlKitNum: .cellId$, "variance", emlDescribe.variance
            @emlKitNum: .cellId$, "sem", emlDescribe.sem
            @emlKitNum: .cellId$, "median", emlDescribe.median
            @emlKitNum: .cellId$, "q1", emlDescribe.q1
            @emlKitNum: .cellId$, "q3", emlDescribe.q3
            @emlKitNum: .cellId$, "iqr", emlDescribe.iqr
            @emlKitNum: .cellId$, "min", emlDescribe.min
            @emlKitNum: .cellId$, "max", emlDescribe.max
            @emlKitNum: .cellId$, "range", emlDescribe.range
            @emlKitNum: .cellId$, "skewness", emlDescribe.skewness
            @emlKitNum: .cellId$, "kurtosis", emlDescribe.kurtosis
            @emlKitNum: .cellId$, "ci_low", emlDescribe.ci95Lower
            @emlKitNum: .cellId$, "ci_high", emlDescribe.ci95Upper
        endif

    elsif .proc$ = "emlRunRegressionAnalysis"
        # --- 9. LINEAR REGRESSION ------------------------------------------
        @emlRunRegressionAnalysis: .tableId, .colA$, .colB$
        if emlRunRegressionAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunRegressionAnalysis.error$
        else
            @emlKitNum: .cellId$, "n", emlLinearRegression.n
            @emlKitNum: .cellId$, "slope", emlLinearRegression.slope
            @emlKitNum: .cellId$, "intercept", emlLinearRegression.intercept
            @emlKitNum: .cellId$, "slope_se", emlLinearRegression.seSlope
            @emlKitNum: .cellId$, "intercept_se",
            ... emlLinearRegression.seIntercept
            @emlKitNum: .cellId$, "slope_t", emlLinearRegression.tSlope
            @emlKitNum: .cellId$, "intercept_t", emlLinearRegression.tIntercept
            @emlKitNum: .cellId$, "slope_p", emlLinearRegression.pSlope
            @emlKitNum: .cellId$, "intercept_p", emlLinearRegression.pIntercept
            @emlKitNum: .cellId$, "r", emlLinearRegression.r
            @emlKitNum: .cellId$, "r_squared", emlLinearRegression.rSquared
            @emlKitNum: .cellId$, "residual_se", emlLinearRegression.seResidual
            @emlKitNum: .cellId$, "f", emlLinearRegression.fStat
            @emlKitNum: .cellId$, "df_between", emlLinearRegression.dfReg
            @emlKitNum: .cellId$, "df_within", emlLinearRegression.dfRes
            @emlKitNum: .cellId$, "p", emlLinearRegression.pF
            if emlLinearRegression.n > 2
                .adjR2 = 1 - (1 - emlLinearRegression.rSquared)
                ... * (emlLinearRegression.n - 1) / (emlLinearRegression.n - 2)
                @emlKitNum: .cellId$, "adj_r_squared", .adjR2
            endif
        endif

    elsif .proc$ = "emlRunGroupedRegression"
        # --- 9b. GROUPED REGRESSION (prereq already ran the overall fit) --
        @emlRunGroupedRegression: .tableId, .colA$, .colB$, .colC$
        @emlKitNum: .cellId$, "overall_slope",
        ... emlRunGroupedRegression.ovSlope
        @emlKitNum: .cellId$, "overall_intercept",
        ... emlRunGroupedRegression.ovIntercept
        @emlKitNum: .cellId$, "overall_slope_se",
        ... emlRunGroupedRegression.ovSeSlope
        @emlKitNum: .cellId$, "overall_intercept_se",
        ... emlRunGroupedRegression.ovSeIntercept
        @emlKitNum: .cellId$, "overall_slope_t",
        ... emlRunGroupedRegression.ovTSlope
        @emlKitNum: .cellId$, "overall_intercept_t",
        ... emlRunGroupedRegression.ovTIntercept
        @emlKitNum: .cellId$, "overall_slope_p",
        ... emlRunGroupedRegression.ovPSlope
        @emlKitNum: .cellId$, "overall_intercept_p",
        ... emlRunGroupedRegression.ovPIntercept
        # The orchestrator publishes the overall COEFFICIENTS but not the
        # overall FIT statistics. Re-run the same call the row's own prereq
        # names -- @emlRunRegressionAnalysis (respCol, predCol) -- and read
        # them off emlLinearRegression, which is exactly where
        # @emlRunGroupedRegression itself reads its overall numbers from.
        # This is one computation read a second time for output, not a
        # second way of computing it. It must happen BEFORE the per-group
        # loop below, which overwrites emlLinearRegression on every group.
        @emlRunRegressionAnalysis: .tableId, .colB$, .colA$
        if emlRunRegressionAnalysis.error$ = ""
            @emlKitNum: .cellId$, "overall_r_squared",
            ... emlLinearRegression.rSquared
            @emlKitNum: .cellId$, "overall_residual_se",
            ... emlLinearRegression.seResidual
            @emlKitNum: .cellId$, "n", emlLinearRegression.n
        endif
        @emlKitNum: .cellId$, "pg_total", emlRunGroupedRegression.pgTotal
        @emlKitNum: .cellId$, "pg_run", emlRunGroupedRegression.pgRun
        @emlKitNum: .cellId$, "pg_skipped", emlRunGroupedRegression.pgSkipped

        # Per-group coefficients: re-derive with the SAME kernel and the SAME
        # extractor @emlRunGroupedRegression itself calls internally
        # (@eml_getGroupPairedData + @emlLinearRegression) -- this is reading
        # the same computation a second time for output, not a second
        # computation.
        for .gi from 1 to emlRunGroupedRegression.pgTotal
            if emlRunGroupedRegression.pgN [.gi] >= 3
                @emlKitSlug: emlRunGroupedRegression.pgLabel$ [.gi]
                .gLabel$ = emlKitSlug.result$
                @eml_getGroupPairedData: .tableId, .colA$, .colB$, .colC$,
                ... emlRunGroupedRegression.pgLabel$ [.gi]
                @emlLinearRegression: eml_getGroupPairedData.dataX#,
                ... eml_getGroupPairedData.dataY#
                if emlLinearRegression.error$ = ""
                    # PREFIXED "grp_": the group label is data, and a group
                    # named e.g. "adj" would otherwise mint the key
                    # "adj_r_squared", colliding with the canonical name for
                    # the overall model's adjusted R-squared.
                    .gk$ = "grp_" + .gLabel$
                    @emlKitNum: .cellId$, .gk$ + "_slope",
                    ... emlLinearRegression.slope
                    @emlKitNum: .cellId$, .gk$ + "_intercept",
                    ... emlLinearRegression.intercept
                    @emlKitNum: .cellId$, .gk$ + "_r_squared",
                    ... emlLinearRegression.rSquared
                    @emlKitNum: .cellId$, .gk$ + "_n",
                    ... emlLinearRegression.n
                    @emlKitNum: .cellId$, .gk$ + "_slope_se",
                    ... emlLinearRegression.seSlope
                    @emlKitNum: .cellId$, .gk$ + "_slope_t",
                    ... emlLinearRegression.tSlope
                    @emlKitNum: .cellId$, .gk$ + "_p",
                    ... emlLinearRegression.pSlope
                endif
            endif
        endfor

    elsif .proc$ = "emlRunNormalityAnalysis"
        # --- 11. NORMALITY -------------------------------------------------
        @emlRunNormalityAnalysis: .tableId, .colA$, .test$
        if emlRunNormalityAnalysis.error$ <> ""
            .refused = 1
            .refuseReason$ = emlRunNormalityAnalysis.error$
        else
            @emlKitNum: .cellId$, "n", emlRunNormalityAnalysis.nValid
            @emlKitNum: .cellId$, "mean", emlRunNormalityAnalysis.mean
            @emlKitNum: .cellId$, "sd", emlRunNormalityAnalysis.sd
            @emlKitNum: .cellId$, "median", emlRunNormalityAnalysis.median
            @emlKitNum: .cellId$, "skewness", emlRunNormalityAnalysis.skewness
            @emlKitNum: .cellId$, "kurtosis", emlRunNormalityAnalysis.kurtosis
            if emlRunNormalityAnalysis.swError$ = ""
                @emlKitNum: .cellId$, "w_statistic",
                ... emlRunNormalityAnalysis.swW
                @emlKitNum: .cellId$, "p", emlRunNormalityAnalysis.swP
            endif
        endif

    elsif .proc$ = "emlRunRepeatedMeasuresAnalysis"
        ... or .proc$ = "emlRunFriedmanAnalysis"
        # --- 12/13. REPEATED-MEASURES ANOVA (GG) / FRIEDMAN ----------------
        .doPostHoc = number (.posthoc$)
        @emlExtractConditionMatrix: .tableId, .colA$
        if .proc$ = "emlRunRepeatedMeasuresAnalysis"
            @emlRunRepeatedMeasuresAnalysis: .tableId, "", .colA$,
            ... .doPostHoc, .adjust$
            .thisErr$ = emlRunRepeatedMeasuresAnalysis.error$
        else
            @emlRunFriedmanAnalysis: .tableId, "", .colA$, .doPostHoc,
            ... .adjust$
            .thisErr$ = ""
            if emlExtractConditionMatrix.error$ <> ""
                .thisErr$ = emlExtractConditionMatrix.error$
            endif
        endif

        if .thisErr$ <> ""
            .refused = 1
            .refuseReason$ = .thisErr$
        else
            @emlKitNum: .cellId$, "n", emlExtractConditionMatrix.n
            @emlKitNum: .cellId$, "n_excluded",
            ... emlExtractConditionMatrix.nExcluded
            if .proc$ = "emlRunRepeatedMeasuresAnalysis"
                @emlKitNum: .cellId$, "f", emlRMAnovaTest.fStat
                @emlKitNum: .cellId$, "df_between", emlRMAnovaTest.dfCond
                @emlKitNum: .cellId$, "df_within", emlRMAnovaTest.dfErr
                @emlKitNum: .cellId$, "p", emlRMAnovaTest.p
                @emlKitNum: .cellId$, "gg_epsilon", emlRMAnovaTest.ggEpsilon
                @emlKitNum: .cellId$, "gg_p", emlRMAnovaTest.pGG
                # ssCond / ssErr were already in hand for partial eta-squared
                # below and were simply not written out; condMean# likewise.
                @emlKitNum: .cellId$, "ss_between", emlRMAnovaTest.ssCond
                @emlKitNum: .cellId$, "ss_within", emlRMAnovaTest.ssErr
                for .ci from 1 to emlExtractConditionMatrix.k
                    @emlKitSlug: emlExtractConditionMatrix.colLabel$ [.ci]
                    @emlKitNum: .cellId$, "mean_" + emlKitSlug.result$,
                    ... emlRMAnovaTest.condMean# [.ci]
                endfor
                .denom = emlRMAnovaTest.ssCond + emlRMAnovaTest.ssErr
                if .denom > 0
                    @emlKitNum: .cellId$, "partial_eta_squared",
                    ... emlRMAnovaTest.ssCond / .denom
                endif
            else
                @emlKitNum: .cellId$, "chi_square", emlFriedmanTest.chiSq
                @emlKitNum: .cellId$, "df", emlFriedmanTest.df
                @emlKitNum: .cellId$, "p", emlFriedmanTest.p
                .kN = emlExtractConditionMatrix.n
                .kK = emlExtractConditionMatrix.k
                if .kN > 0 and .kK > 1
                    @emlKitNum: .cellId$, "kendalls_w",
                    ... emlFriedmanTest.chiSq / (.kN * (.kK - 1))
                endif
            endif

            if .doPostHoc = 1
                if variableExists ("emlRMPostHoc.nPairs")
                    for .pp from 1 to emlRMPostHoc.nPairs
                        .ai = emlRMPostHoc.pairLabelA [.pp]
                        .bi = emlRMPostHoc.pairLabelB [.pp]
                        @emlKitPairName: emlExtractConditionMatrix.colLabel$
                        ... [.ai], emlExtractConditionMatrix.colLabel$ [.bi]
                        @emlKitNum: .cellId$,
                        ... "posthoc_" + emlKitPairName.result$ + "_p",
                        ... emlRMPostHoc.rawP# [.pp]
                        @emlKitNum: .cellId$,
                        ... "posthoc_" + emlKitPairName.result$ + "_padj",
                        ... emlRMPostHoc.adj# [.pp]
                    endfor
                endif
            endif
        endif

    else
        .refused = 1
        .refuseReason$ = "RUNNER DEFECT: unrecognised analysis-lane "
        ... + "procedure """ + .proc$ + """ -- add a branch to "
        ... + "@emlKitDispatchAnalysis."
    endif
endproc

# ----------------------------------------------------------------------------
# @emlKitCorrelationRanSomething -- @emlRunCorrelationAnalysis does not itself
# set .error$ when every REQUESTED correlation family failed (e.g. zero
# variance on both Pearson and Spearman): it leaves .error$ = "" with every
# numeric output undefined, which would otherwise emit as a silent "ok" cell
# with no numbers on it -- exactly the "silent fallback" the shared schema
# forbids. This is a runner-side check, not a library patch: it reads the
# orchestrator's own .pearErr$ / .spearErr$ (still live in its namespace,
# read directly after the call) and decides whether the cell actually
# produced anything for what .test$ asked for.
# Output: .ranSomething (1 = at least one requested family succeeded),
#         .reason$ (composed refusal text when .ranSomething = 0)
# ----------------------------------------------------------------------------
procedure emlKitCorrelationRanSomething: .test$
    .ranSomething = 0
    .reason$ = ""
    if .test$ = "pearson" or .test$ = "both"
        if emlRunCorrelationAnalysis.pearErr$ = ""
            .ranSomething = 1
        endif
    endif
    if .test$ = "spearman" or .test$ = "both"
        if emlRunCorrelationAnalysis.spearErr$ = ""
            .ranSomething = 1
        endif
    endif
    if .ranSomething = 0
        .reason$ = "No correlation could be computed."
        if emlRunCorrelationAnalysis.pearErr$ <> ""
            .reason$ = .reason$ + " Pearson: "
            ... + emlRunCorrelationAnalysis.pearErr$
        endif
        if emlRunCorrelationAnalysis.spearErr$ <> ""
            .reason$ = .reason$ + " Spearman: "
            ... + emlRunCorrelationAnalysis.spearErr$
        endif
    endif
endproc


# ============================================================================
# SECTION 8 -- @emlKitDispatchSurvey: the 4 survey-lane kernels
# ============================================================================
# These four have no menu item and no dialog -- matrix.tsv calls them
# directly, on a matrix/scalar input rather than a Table, so each branch
# below builds that input from the dataset's own CSV first.
# Output: .refused, .refuseReason$
# ============================================================================
procedure emlKitDispatchSurvey: .cellId$, .proc$, .tableId, .colA$, .colB$,
    ... .colC$, .conf$, .correction$

    .refused = 0
    .refuseReason$ = ""

    if .proc$ = "emlCronbachAlpha"
        @emlKitTableToMatrix: .tableId
        .confN = number (.conf$)
        @emlCronbachAlpha: emlKitTableToMatrix.m##, .confN
        if emlCronbachAlpha.error$ <> ""
            .refused = 1
            .refuseReason$ = emlCronbachAlpha.error$
        else
            @emlKitNum: .cellId$, "alpha", emlCronbachAlpha.alpha
            @emlKitNum: .cellId$, "alpha_ci_low", emlCronbachAlpha.ciLow
            @emlKitNum: .cellId$, "alpha_ci_high", emlCronbachAlpha.ciHigh
            @emlKitNum: .cellId$, "n", emlCronbachAlpha.n
            @emlKitNum: .cellId$, "k", emlCronbachAlpha.k
            @emlKitNum: .cellId$, "n_excluded", emlCronbachAlpha.nExcluded
            for .j from 1 to emlCronbachAlpha.k
                @emlKitSlug: emlKitTableToMatrix.colLabelClean$ [.j]
                @emlKitNum: .cellId$,
                ... "alpha_if_deleted_" + emlKitSlug.result$,
                ... emlCronbachAlpha.alphaIfDeleted# [.j]
            endfor
        endif

    elsif .proc$ = "emlAlphaInfluence"
        @emlKitTableToMatrix: .tableId
        @emlAlphaInfluence: emlKitTableToMatrix.m##
        if emlAlphaInfluence.error$ <> ""
            .refused = 1
            .refuseReason$ = emlAlphaInfluence.error$
        else
            @emlKitNum: .cellId$, "alpha", emlAlphaInfluence.alphaFull
            @emlKitNum: .cellId$, "n", emlAlphaInfluence.n
            @emlKitNum: .cellId$, "k", emlAlphaInfluence.k
            @emlKitNum: .cellId$, "n_excluded", emlAlphaInfluence.nExcluded
            @emlKitNum: .cellId$, "delta_max", emlAlphaInfluence.deltaMax
            @emlKitNum: .cellId$, "delta_max_row",
            ... emlAlphaInfluence.deltaMaxRow
            for .j from 1 to emlAlphaInfluence.n
                @emlKitNum: .cellId$,
                ... "delta_row_" + string$ (emlAlphaInfluence.rowIndex# [.j]),
                ... emlAlphaInfluence.delta# [.j]
            endfor
        endif

    elsif .proc$ = "emlChiSquareIndependence"
        @emlKitTableToMatrix: .tableId
        .corrN = number (.correction$)
        @emlChiSquareIndependence: emlKitTableToMatrix.m##, .corrN
        if emlChiSquareIndependence.error$ <> ""
            .refused = 1
            .refuseReason$ = emlChiSquareIndependence.error$
        else
            @emlKitNum: .cellId$, "chi_square", emlChiSquareIndependence.chiSq
            @emlKitNum: .cellId$, "df", emlChiSquareIndependence.df
            @emlKitNum: .cellId$, "p", emlChiSquareIndependence.p
            @emlKitNum: .cellId$, "cramers_v",
            ... emlChiSquareIndependence.cramersV
            @emlKitNum: .cellId$, "n", emlChiSquareIndependence.n
            @emlKitNum: .cellId$, "min_expected",
            ... emlChiSquareIndependence.minExpected
            @emlKitNum: .cellId$, "n_cells_below5",
            ... emlChiSquareIndependence.nCellsBelow5
        endif

    elsif .proc$ = "emlWilsonInterval"
        @emlKitFindColRaw: .tableId, "case"
        .caseCol$ = emlKitFindColRaw.rawName$
        @emlKitFindColRaw: .tableId, "x"
        .xCol$ = emlKitFindColRaw.rawName$
        @emlKitFindColRaw: .tableId, "n"
        .nCol$ = emlKitFindColRaw.rawName$
        selectObject: .tableId
        .nRows = Get number of rows
        .row = 0
        .r = 1
        while .r <= .nRows and .row = 0
            .caseHere$ = Get value: .r, .caseCol$
            if .caseHere$ = .colA$
                .row = .r
            endif
            .r = .r + 1
        endwhile
        if .row = 0
            .refused = 1
            .refuseReason$ = "RUNNER DEFECT: case """ + .colA$
            ... + """ not found in " + "lane_survey_wilson_cases.csv."
        else
            .x = Get value: .row, .xCol$
            .n = Get value: .row, .nCol$
            .confN = number (.conf$)
            @emlWilsonInterval: .x, .n, .confN
            if emlWilsonInterval.error$ <> ""
                .refused = 1
                .refuseReason$ = emlWilsonInterval.error$
            else
                @emlKitNum: .cellId$, "prop_hat", emlWilsonInterval.propHat
                @emlKitNum: .cellId$, "ci_low", emlWilsonInterval.ciLow
                @emlKitNum: .cellId$, "ci_high", emlWilsonInterval.ciHigh
                @emlKitNum: .cellId$, "n", .n
            endif
        endif

    else
        .refused = 1
        .refuseReason$ = "RUNNER DEFECT: unrecognised survey-lane "
        ... + "procedure """ + .proc$ + """ -- add a branch to "
        ... + "@emlKitDispatchSurvey."
    endif
endproc


# ============================================================================
# SECTION 9 -- write the results TSV, print the summary
# ============================================================================
writeFile: "out/praat_results.tsv", emlKitTSVBuf$

clearinfo
writeInfoLine: "EML Stats & Graphs -- matrix.tsv walkthrough (Praat side)"
appendInfoLine: ""
emlKitElapsed = stopwatch - emlKitStartTime
appendInfoLine: "Cells run:        ", emlKitNCells
appendInfoLine: "  -- ok:          ", emlKitNOk
appendInfoLine: "  -- refused:     ", emlKitNRefused
appendInfoLine: "Rows written:     ", emlKitRowCount, " (out/praat_results.tsv)"
appendInfoLine: "Reports written:  ", emlKitNCells, " (out/praat_reports/*.txt)"
appendInfoLine: "Elapsed:          ", fixed$ (emlKitElapsed, 1), " s"
appendInfoLine: ""
if emlKitNMismatch = 0
    appendInfoLine: "All ", emlKitNCells, " cells matched matrix.tsv's own "
    ... + "expect column (ok/refuse)."
else
    appendInfoLine: "*** ", emlKitNMismatch, " cell(s) DISAGREED with "
    ... + "matrix.tsv's expect column: ***"
    appendInfoLine: emlKitMismatchList$
endif
appendInfoLine: "Done."
