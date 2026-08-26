# ============================================================================
# EML Stats : Psychometrics
# ============================================================================
# Module: eml-psychometrics.praat
# Version: 1.10
# Date: 26 August 2026
#
# V1.10: THE APPROVED STAGE 3 AMENDMENTS AND THE VERIFICATION SESSION'S
#        DECLARATION RULINGS. (1) Refusal 8's routing sentence takes Ian's
#        exact wording, verbatim: "Run EML Stats & Graphs > Check & repair
#        data, which lists and repairs all cells with error, then rerun" --
#        no longer DRAFT. The mechanism holding it in agreement with
#        setup.praat's own registration stays on the check side
#        (validate/v132_survey_report_layer.R's eml_menu_canon), unchanged
#        in kind, only in the phrase it now derives (cascade label + bare
#        command label, no "Objects > New >" prefix, no dialog ellipsis).
#        (2) Adds @eml_underscoreNormalize (the forward, space-to-
#        underscore half of the plugin's display-name/identifier pairing;
#        @emlUnderscoreToSpace, eml-output.praat:163, already has the
#        reverse) and refusal 17: two subscale names that collide once
#        both are run through it ("Vocal Health" / "Vocal_Health"), which
#        refusal 13's raw-equality check cannot see. @eml_findDuplicateName
#        gains a `.normalize` argument so refusal 17 reuses the same
#        shared scan refusals 7/13/15 already share, rather than a second
#        nested loop -- its one comparison line is untouched, so the
#        existing negative controls for 7/13/15 still seed the same guard
#        they always did.
#
# V1.9: THE ONE COMPUTATIONAL ADDITION THE PRESENTATION HALF OF STAGE 2
#       NEEDS THAT WASN'T ALREADY SITTING IN V1.8'S OUTPUT ARRAYS. Adds
#       @emlSurveySubscaleDisclosure, which answers "which of THIS
#       subscale's own items carried a recognised missing-value
#       placeholder cell" -- @emlSurveyValidateDeclaration's own
#       .disclosureCount/.disclosureItem$[]/.disclosureSpelling$[] (V1.7)
#       already answer that question for the DECLARATION AS A WHOLE and
#       already print the run-wide sentence unconditionally, but do not
#       keep the per-item cell count or which spelling landed on which
#       item -- exactly the granularity a per-subscale report block
#       (scripts/eml-survey.praat) needs and the run-wide aggregate
#       discards. Rather than widen @emlSurveyValidateDeclaration's own
#       output contract a second time (V1.6's own header explains why that
#       is fraught: v129's exhaustive sweep enforces an exact output count
#       against every one of its seventeen exit paths, and the last
#       attempt to add fields inside that block broke it on refusals
#       11/13/14/15), the new procedure independently RE-CALLS
#       @eml_scanColumnForPlaceholders -- the same composed classifier
#       @emlSurveyValidateDeclaration itself already calls once per item,
#       V1.7 -- scoped to one subscale's own items, in the exact order
#       @emlSurveyScoreScales (V1.8) already assembled them in. Read-only,
#       calls no new classifier, restates no spelling list, and is safe to
#       call after @emlSurveyValidateDeclaration has moved on to whatever
#       it does next, since it touches nothing that procedure left behind.
#       No report text lives here either -- see @emlSurveyScoreScales's
#       own header, below, for why this module stops at raw values and
#       leaves formatting to the next stage.
#
# V1.8: THE COMPUTATIONAL HALF OF STAGE 2. Adds @eml_reverseScoreMatrix
#       (the reversal transform, y = min + max - x on a subscale's declared
#       printed range, matrix in matrix out, vectorized) and
#       @emlSurveyScoreScales (per-subscale routing driven entirely by
#       @emlSurveyValidateDeclaration's own leftover output -- assembles
#       each subscale's item matrix in declared order, reverse-scores it,
#       and drives @emlCronbachAlpha and @emlAlphaInfluence per subscale,
#       plus item-rest/item-total via @emlPearsonCorrelation and the
#       per-respondent complete-case scale-score mean). A subscale whose
#       kernel refuses (e.g. fewer than three complete respondents) carries
#       that refusal verbatim in its own output slot; every other subscale
#       is unaffected, by construction -- the per-subscale loop runs the
#       identical sequence of steps for every subscale with no branch on
#       an earlier one's result, and both kernels already leave their own
#       outputs safely `undefined` with .error$ named on refusal. The
#       confidence level is read from @emlReportAlpha (eml-analysis.praat),
#       never a literal; no report text and no dialog are built here --
#       see @emlSurveyScoreScales's own header, below, for the full design
#       notes (why the transform is vectorized, why item-rest/item-total
#       share alpha's own complete-case matrix, why the KR-20 condition is
#       a copy and not a recomputation).
#
# V1.7: THE SUPERSEDING CELL RULING. Refusal 8 used to refuse on every
#       cell it could not read as a number, with no further question
#       asked. That is superseded, in three branches. (1) A cell matching
#       one of @emlRepairClassify's own kind-3 missing-value spellings
#       (na, n/a, n.a., nan, null, nil, -, --, ., ?, missing --
#       case-insensitive; that list lives ONLY at @emlRepairClassify,
#       eml-extract.praat:2665, and is not restated here) is no longer
#       refused: it is treated as ordinary missingness, exactly like a
#       blank cell. (2) Whenever any such placeholder was found, a
#       disclosure is printed (appendInfoLine) and returned
#       (.disclosureCount / .disclosureSpelling$[] / .disclosureItem$[] /
#       .disclosure$), unconditionally on that fact alone -- even when the
#       declaration goes on to refuse for an unrelated reason. (3) Any
#       OTHER cell refusal 8 could not read still refuses, at first find,
#       now also naming "Check & repair data" (Objects > New > EML Stats &
#       Graphs > Check & repair data...) by name and menu location; no
#       second inventory of bad cells is built here, since that screen
#       already is one. A whitespace-only data cell is NOT reclassified as
#       a placeholder yet -- @emlRepairClassify does not itself recognise
#       whitespace as kind 3 (a filed, not-yet-landed fix in the other
#       lane) -- so it keeps refusing under refusal 8's existing Fix 3
#       pre-check, unchanged, until that fix lands. New internal helper
#       @eml_scanColumnForPlaceholders composes @eml_classifyCell (which
#       kinds are even "unreadable") with @emlRepairClassify (which of
#       those are a recognised placeholder); no new classifier or
#       placeholder list is written in this module. All new user-facing
#       wording stays DRAFT, awaiting Ian's approval, in the same
#       DRAFT LANGUAGE block as refusals 1-16's own messages.
#
# V1.1: Adds @emlSurveyValidateDeclaration, the survey module's declaration
#       validator. It checks a data Table against a scales Table and an
#       items Table (the two-CSV declaration described in
#       evidence/csv/lane_survey_declared_SCHEMA.md) and refuses before any
#       reliability number is computed. Stage 1 of the survey module build:
#       schemas, validator, oracles. No reversal transform, no per-subscale
#       routing, no report -- those are wired to this validator later and do
#       not live in this module.
#
# V1.2: Adds refusals 6-10 to @emlSurveyValidateDeclaration -- four
#       declaration-shape faults the verification pass proved pass silently
#       (an illegal `reversed` value, a duplicated item name, an illegal
#       scale `type`, a non-numeric item data column) plus one ordering
#       repair (a declared min not below its declared max, now caught as a
#       declaration fault instead of misreported as a bad respondent row).
#       Also exposes, once, the KR-20 naming condition (declared range
#       spans exactly two values) as a per-scale output, so Stage 2 does
#       not re-derive it. No reversal transform, no per-subscale routing,
#       no report -- still Stage 1 only.
#
# V1.3: An adversarial pass found that the scales file was validated far
#       less thoroughly than the items file: a missing required column
#       (either file) HALTED Praat outright instead of refusing, and a
#       non-numeric or missing declared min/max endpoint validated clean
#       (both guards that read it compare against `undefined`, which is
#       false against everything). Adds refusals 11-14 to close the class:
#       11 (a required column missing from either declaration file), 12
#       (a non-numeric or missing declared min/max endpoint), 13 (a scale
#       name declared more than once), 14 (an empty scale name). Refusal 7
#       (item name declared more than once) is refactored, not changed in
#       behavior, onto the new shared @eml_findDuplicateName helper that
#       refusal 13 also uses, so the items file and the scales file are no
#       longer checked for duplicates by two different pieces of logic.
#       Also fixes refusal 6's message, found in the same pass printing
#       the internal token "--undefined--" for a non-numeric `reversed`
#       value instead of the value as declared.
#
# V1.4: A verification pass found the SAME "proxy checking" pattern this
#       module keeps re-exhibiting: an existing classifier called and only
#       part of its verdict consumed. Refusal 8 (Finding 1) called
#       @emlAuditColumn on a scale item's data column and read only its
#       kind-3 ("unreadable") count, discarding kinds 2 (locale-comma), 4
#       (coerced) and 5 (leading-dot) -- each a cell "Get value:"
#       mishandles as badly as kind 3, proved live on the committed
#       fixture (a locale comma silently misreads as a different number;
#       a leading dot silently vanishes into listwise deletion). All four
#       now refuse; kind 1 (genuinely empty) stays deliberately exempt,
#       stated at the call site rather than left implicit. Refusal 12's
#       message (Finding 2) tested `.badRawValue$ = ""` to decide between
#       naming a value and saying a cell is empty, which is not Praat's
#       own missing-value token "--undefined--" -- a round-tripped
#       declaration containing that token printed it verbatim to the
#       user; now decided by @eml_classifyCell's kind, which already
#       folds both spellings of "nothing here" together. Refusal 14
#       (Finding 6) tested a scale name for exact empty string, not
#       trimmed, so a whitespace-only or round-tripped-token name
#       declared a live, unmatchable subscale; now decided the same way.
#       Every other @eml-prefixed call in this procedure was swept for
#       the same pattern (Finding 1's closing instruction) and either
#       already reads its whole verdict or carries a one-line note on why
#       a given output is deliberately unread (@eml_findDuplicateName's
#       .firstRow; @emlStripHeaderQuotes's .nStripped/.report$). Also
#       closes an unrelated gap the same sweep found: refusal 12's own
#       second @emlAuditColumn call (locating which scale/row a bad
#       endpoint belongs to) never read that call's .error$, unlike
#       refusal 8's identical call a few hundred lines below -- not
#       reachable today (refusal 11 already guarantees "min"/"max" exist)
#       but guarded rather than left to halt on an unassigned indexed
#       variable if that ever changed.
#
# V1.5: Two unchecked directions on the data table, found the same way
#       every prior pass in this module has found its gap: something the
#       schema promises but nothing enforces. (a) Nothing asserted the
#       data table's own column labels are unique. "Get column index:"
#       and "Get value:" both resolve to the FIRST match, so a second,
#       shadowed column of the same name is never read by anything above
#       -- proved live: a data table with two "Q1" columns, the second
#       holding 99 (row 3) and "abc" (row 4), with "Q1" declared once in
#       survey_items.csv, returned refusal 0; the out-of-range 99 and the
#       unreadable "abc" both escaped, because refusal 2 and refusal 8
#       only ever see the first "Q1". Now refusal 15. (b) Refusal 5
#       already holds the scales file and the items file to a two-way
#       standard (an item names an undeclared scale; a declared scale no
#       item uses); nothing held the DATA table and the items file to the
#       same standard in the other direction. The schema says the items
#       file lists every column of the data table, one row per column --
#       a data column absent from survey_items.csv was silently neither
#       scored nor flagged as deliberately ignored. Now refusal 16.
#       Reused, not rewritten: both new refusals answer "does a name
#       repeat" or "is a name declared" the same way refusals 1, 5, 7 and
#       13 already do -- 15 via a one-column scratch Table adapting
#       @eml_findDuplicateName to the data table's own column labels
#       (which are metadata, not a column of data, so the existing helper
#       cannot read them directly) rather than a second nested duplicate
#       scan; 16 via the same "resolves to a declared name" loop refusal
#       1 already runs, in the opposite direction.
#
# V1.6: A fourth adversarial pass closed the output contract as a
#       structure rather than as a one-off patch, and closed a
#       whitespace-only halt.
#         (a) FOUR of the five documented per-scale array outputs
#       (.scaleName$[], .scaleType$[], .scaleMin[], .scaleMax[]) were
#       assigned only in the scales-population loop, which sits AFTER
#       refusal 11's exit -- so a caller reading any of them following a
#       refusal-11 return HALTED with "Undefined indexed variable",
#       verified live on all four, exactly the failure .scaleIsKR20[]
#       alone was already guarded against. All five arrays are now seeded
#       to a defined placeholder ("" for the two string arrays, undefined
#       for the three numeric ones) at procedure entry, before refusal 11
#       or any other refusal can exit, the same way .scaleIsKR20[] already
#       was; the scales-population loop still overwrites every element
#       with its real value whenever it runs. The rule this generalizes is
#       stated once, at the top of the Outputs header below: every
#       documented output holds a defined value on every return.
#         (b) Two documentation defects the same header carried, found in
#       the same pass: .badRawValue$ was documented as "" for an empty
#       cell but held the literal round-tripped token "--undefined--" on
#       that same fixture, disagreeing with the header -- fixed by making
#       the VALUE match the header (forced to "" whenever
#       @eml_classifyCell reads the cell as kind 1, "empty", which already
#       folds both spellings together), so a caller reading .badRawValue$
#       directly, not just .error$'s sentence, never sees the internal
#       token either. .scaleIsKR20[] was documented as 1 or 0 but is
#       `undefined` for every scale on the refusal-11 path specifically
#       (the one path where the scales-population loop that computes it
#       never runs) -- fixed by documenting that third value rather than
#       inventing a fake 0/1 for a range refusal 11 never confirmed even
#       exists.
#         (c) A whitespace-only declared min or max ("Confidence, ,5,
#       ordinal") HALTED Praat with "the cell in row 1 of column min is
#       undefined ... cannot get all numbers in column 2" instead of
#       refusing. Root cause: @eml_strictNumericColumn's pre-scan
#       (eml-extract.praat, outside this lane) recognises only "",
#       "--undefined--" and "?" as unreadable before its fast path calls
#       Praat's own "Get all numbers in column:", and a whitespace-only
#       cell matches none of the three. Fixed inside this module, without
#       touching or duplicating that classifier: the new internal helper
#       @eml_findWhitespaceOnlyCell classifies "min", then "max", with
#       @eml_classifyCell (the classifier this procedure already calls
#       for exactly this kind of question) BEFORE either column is ever
#       handed to @emlRequireNumericColumn / @emlAuditColumn, because
#       calling either on a column already carrying the landmine cell IS
#       the crash, not a defence against it. A whitespace-only endpoint
#       now refuses as refusal 12's existing "empty" branch, not a new
#       code.
#
# Part of the EML Stats library (EML Praat Tools).
# License: GPL-3.0-or-later
#
# Provides: @emlCronbachAlpha, @emlAlphaInfluence,
#   @emlSurveyValidateDeclaration, @emlSurveyScoreScales,
#   @emlSurveySubscaleDisclosure
#
# Internal helpers: @eml_listwiseComplete, @eml_underscoreNormalize,
#   @eml_findDuplicateName, @eml_findWhitespaceOnlyCell,
#   @eml_scanColumnForPlaceholders, @eml_reverseScoreMatrix
#
# Dependencies: @emlCronbachAlpha and @emlAlphaInfluence use only Praat
# built-in vector and matrix primitives and the built-in F distribution.
#
#   @emlSurveyValidateDeclaration (v1.1) requires @emlStripHeaderQuotes from
#   eml-extract.praat. The calling script must include extract
#   before psychometrics:
#     include eml-extract.praat
#     include eml-psychometrics.praat
#
#   V1.2's refusal 8 additionally calls @emlAuditColumn, also from
#   eml-extract.praat -- no new include is needed beyond the one above.
#
#   V1.7's cell ruling additionally calls @emlRepairClassify (via the new
#   internal helper @eml_scanColumnForPlaceholders), also from
#   eml-extract.praat -- no new include is needed beyond the one above.
#
#   V1.3's refusal 11 additionally calls @emlRequireColumnPresent and
#   refusal 12 calls @emlRequireNumericColumn, both from
#   eml-inferential.praat. The calling script must include inferential
#   before psychometrics as well:
#     include eml-extract.praat
#     include eml-inferential.praat
#     include eml-psychometrics.praat
#
#   V1.8's @emlSurveyScoreScales additionally calls @emlPearsonCorrelation
#   (eml-inferential.praat, already required above) and @emlReportAlpha
#   (eml-analysis.praat, a NEW dependency this module did not previously
#   have). @emlReportAlpha has no further dependency of its own beyond
#   Praat built-ins, so no other module needs including alongside it. A
#   caller that uses @emlSurveyScoreScales needs:
#     include eml-extract.praat
#     include eml-inferential.praat
#     include eml-analysis.praat
#     include eml-psychometrics.praat
#   A caller that only uses @emlSurveyValidateDeclaration (Stage 1) still
#   needs no more than the three-include list above it.
#
# All procedures use the "eml" prefix (EML Stats) to avoid
# namespace collisions with user scripts.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

# ----------------------------------------------------------------------------
# @eml_listwiseComplete
# Internal helper: remove every row of a matrix that contains at least
# one undefined cell (listwise deletion).
# Input:  .data## — numeric matrix, rows = respondents, columns = items
# Output: .clean##    — the matrix restricted to complete rows
#         .nKept      — number of complete rows
#         .nExcluded  — number of rows removed
# ----------------------------------------------------------------------------

procedure eml_listwiseComplete: .data##
    .nRows = numberOfRows (.data##)
    .nCols = numberOfColumns (.data##)

    # A row sum is undefined exactly when the row holds an undefined
    # cell, because arithmetic with undefined propagates.
    .rowTotal# = rowSums# (.data##)

    .nKept = 0
    for .i from 1 to .nRows
        if .rowTotal# [.i] <> undefined
            .nKept = .nKept + 1
        endif
    endfor
    .nExcluded = .nRows - .nKept

    .clean## = zero## (.nKept, .nCols)
    .row = 0
    for .i from 1 to .nRows
        if .rowTotal# [.i] <> undefined
            .row = .row + 1
            for .j from 1 to .nCols
                .clean## [.row, .j] = .data## [.i, .j]
            endfor
        endif
    endfor
endproc

# ============================================================================
# @emlCronbachAlpha
# ============================================================================
# Cronbach's alpha: internal consistency of a k-item scale.
#
# The input is one matrix, rows = respondents, columns = items, so a
# 20-respondent 5-item scale arrives as a 20 x 5 matrix. Rows holding
# an undefined cell are removed before computation (listwise deletion)
# and the removal is disclosed in .nExcluded.
#
# The confidence interval uses the Feldt (1965) F-distribution method
# with df1 = n - 1 and df2 = (n - 1)(k - 1), matching R's psych::alpha.
#
# ITS LEVEL IS AN ARGUMENT, not a constant, the same way @emlCI and the
# sibling @emlWilsonInterval take theirs. A caller working at alpha = .01
# gets a 99% interval by asking for one, and .confidence is echoed back
# beside the bounds so a report printing them can name the level it prints.
#
# Arguments:
#   .data##      - numeric matrix; rows = respondents, columns = items
#   .confidence  - confidence level as a proportion, e.g. 0.95
#
# Output:
#   .alpha            - Cronbach's alpha (covariance-based, sample
#                       variances with n - 1 denominator)
#   .ciLow            - lower bound of the Feldt interval
#   .ciHigh           - upper bound of the Feldt interval
#   .confidence       - the level the bounds were computed at, echoed
#   .k                - number of items (columns)
#   .n                - number of respondents used (complete rows)
#   .nExcluded        - rows removed by listwise deletion
#   .alphaIfDeleted#  - vector, length k: alpha of the scale with that
#                       item removed (undefined for every item when
#                       k = 2, because a one-item scale has no alpha)
#   .error$           - error message, or "" if valid
#
# Access pattern:
#   @emlCronbachAlpha: responses##, 0.95
#   a = emlCronbachAlpha.alpha
#   dropTwo = emlCronbachAlpha.alphaIfDeleted# [2]
#
# Notes:
#   - Items are assumed already scored in a consistent direction;
#     reverse-scoring is the caller's responsibility. An item scored
#     in the wrong direction lowers alpha — it is not detected here.
#   - Requires k >= 2 items and, after listwise deletion, n >= 3
#     respondents (the Feldt CI needs n - 1 >= 2).
#   - .confidence must lie strictly between 0 and 1; anything else is
#     refused in .error$ rather than handed to invFisherQ, whose tail
#     probability is undefined at 0 and at 1.
#   - Raw values are returned; callers format for display.
# ============================================================================

procedure emlCronbachAlpha: .data##, .confidence
    # Initialize outputs
    .alpha = undefined
    .ciLow = undefined
    .ciHigh = undefined
    .k = undefined
    .n = undefined
    .nExcluded = undefined
    .error$ = ""

    .nRowsIn = numberOfRows (.data##)
    .k = numberOfColumns (.data##)
    .alphaIfDeleted# = zero# (max (.k, 1)) + undefined

    # --- Listwise deletion, disclosed ---
    @eml_listwiseComplete: .data##
    .n = eml_listwiseComplete.nKept
    .nExcluded = eml_listwiseComplete.nExcluded
    .work## = eml_listwiseComplete.clean##

    # --- Input validation ---
    if .confidence = undefined or .confidence <= 0 or .confidence >= 1
        .error$ = "confidence must be strictly between 0 and 1, "
        ... + "e.g. 0.95"
    elsif .k < 2
        .error$ = "Alpha needs at least 2 items; the matrix has "
        ... + string$ (.k) + "."
    elsif .n < 3
        .error$ = "Alpha needs at least 3 complete respondents; "
        ... + string$ (.nRowsIn) + " arrived and " + string$ (.n)
        ... + " remained after listwise deletion."
    else
        # --- Center per column before any variance ---
        # Variance is translation-invariant, and the sum-of-squares
        # formula below loses its signal to cancellation when a large
        # common offset rides on every value (data at 1e8 squares to
        # 1e16, past double precision's reach). Centering first keeps
        # the sums at the scale of the spread.
        .rawColSum# = columnSums# (.work##)
        .ones# = zero# (.n) + 1
        .work## = .work## - outer## (.ones#, .rawColSum# * (1 / .n))

        # --- Item variances (vectorized: per-column sum and sum of
        #     squares, sample variance with n - 1 denominator) ---
        .colSum# = columnSums# (.work##)
        .colSumSq# = columnSums# (.work## * .work##)
        .itemVar# = (.colSumSq# - .colSum# * .colSum# / .n) / (.n - 1)

        # --- Total-score variance ---
        .total# = rowSums# (.work##)
        .sdTotal = stdev (.total#)
        .varTotal = .sdTotal * .sdTotal

        if .varTotal = 0
            .error$ = "The total score has zero variance; "
            ... + "alpha is undefined."
        else
            # --- Alpha ---
            .sumItemVar = sum (.itemVar#)
            .alpha = (.k / (.k - 1)) * (1 - .sumItemVar / .varTotal)

            # --- Feldt (1965) confidence interval ---
            # Both tails come from .confidence, so the level the caller
            # asked for is the level the bounds carry. The two-sided tail
            # is (1 - confidence) / 2 at each end, which reproduces the
            # .025 / .975 pair exactly at the conventional 0.95.
            .tail = (1 - .confidence) / 2
            .df1 = .n - 1
            .df2 = (.n - 1) * (.k - 1)
            .ciLow = 1 - (1 - .alpha) * invFisherQ (.tail, .df1, .df2)
            .ciHigh = 1 - (1 - .alpha) * invFisherQ (1 - .tail, .df1, .df2)

            # --- Alpha if item deleted ---
            # For k = 2 the reduced scale has one item and no alpha;
            # the vector stays undefined in that case.
            if .k >= 3
                for .j from 1 to .k
                    # Column j via matrix-vector product with the
                    # j-th unit vector.
                    .unit# = zero# (.k)
                    .unit# [.j] = 1
                    .colJ# = mul# (.work##, .unit#)
                    .reduced# = .total# - .colJ#
                    .sdReduced = stdev (.reduced#)
                    .varReduced = .sdReduced * .sdReduced
                    if .varReduced > 0
                        .sumVarReduced = .sumItemVar - .itemVar# [.j]
                        .alphaIfDeleted# [.j] = ((.k - 1) / (.k - 2))
                        ... * (1 - .sumVarReduced / .varReduced)
                    endif
                endfor
            endif
        endif
    endif
endproc

# ============================================================================
# @emlAlphaInfluence
# ============================================================================
# Respondent influence on Cronbach's alpha: leave-one-out jackknife over
# respondents. Where alpha-if-deleted asks whether one ITEM is spoiling
# the scale, this asks whether one RESPONDENT is: alpha is recomputed
# with each respondent removed, and each removal's effect on alpha is
# reported as a delta against the full complete-case alpha.
#
# The input is one matrix, rows = respondents, columns = items, the same
# shape @emlCronbachAlpha takes. Listwise deletion runs first, identical
# to the alpha kernel, and is disclosed in .nExcluded. All indexed
# outputs run over the SURVIVING rows, and .rowIndex# maps each entry
# back to its ORIGINAL row number in the input matrix, so a caller can
# still say "respondent 12" after rows above 12 were deleted.
#
# The kernel reports; it never judges. No thresholds, no outlier labels,
# no automatic exclusion — the numbers go out raw and the caller frames
# the evidence.
#
# Arguments:
#   .data##  - numeric matrix; rows = respondents, columns = items
#
# Output:
#   .alphaFull     - alpha on all complete cases (equals
#                    @emlCronbachAlpha.alpha on the same matrix)
#   .k             - number of items (columns)
#   .n             - number of respondents used (complete rows)
#   .nExcluded     - rows removed by listwise deletion
#   .alphaWithout# - vector, length n: alpha with surviving respondent
#                    j removed (undefined for an entry whose leave-one-
#                    out total score has zero variance)
#   .delta#        - vector, length n: .alphaWithout# [j] - .alphaFull
#   .rowIndex#     - vector, length n: ORIGINAL row number of surviving
#                    respondent j
#   .deltaMax      - largest absolute delta (undefined if every delta
#                    is undefined)
#   .deltaMaxRow   - ORIGINAL row number of that respondent
#   .error$        - error message, or "" if valid
#
# Access pattern:
#   @emlAlphaInfluence: responses##
#   biggest = emlAlphaInfluence.deltaMax
#   who = emlAlphaInfluence.deltaMaxRow          ; original row number
#   d12 = emlAlphaInfluence.delta# [3]           ; 3rd SURVIVING row...
#   row12 = emlAlphaInfluence.rowIndex# [3]      ; ...which is this row
#
# Notes:
#   - Requires k >= 2 items and, after listwise deletion, n >= 3
#     respondents (leave-one-out on fewer would put the covariance
#     on a single row).
#   - Each leave-one-out alpha is computed by downdating the full
#     per-item and total-score sums (one vector operation per
#     respondent), not by rebuilding a submatrix; the loop over
#     respondents is the jackknife itself.
#   - Raw values are returned; callers format for display.
# ============================================================================

procedure emlAlphaInfluence: .data##
    # Initialize outputs
    .alphaFull = undefined
    .k = undefined
    .n = undefined
    .nExcluded = undefined
    .deltaMax = undefined
    .deltaMaxRow = undefined
    .error$ = ""

    .nRowsIn = numberOfRows (.data##)
    .k = numberOfColumns (.data##)

    # --- Listwise deletion, identical to @emlCronbachAlpha ---
    @eml_listwiseComplete: .data##
    .n = eml_listwiseComplete.nKept
    .nExcluded = eml_listwiseComplete.nExcluded
    .work## = eml_listwiseComplete.clean##

    .len = max (.n, 1)
    .alphaWithout# = zero# (.len) + undefined
    .delta# = zero# (.len) + undefined
    .rowIndex# = zero# (.len) + undefined

    # --- Input validation ---
    if .k < 2
        .error$ = "Alpha needs at least 2 items; the matrix has "
        ... + string$ (.k) + "."
    elsif .n < 3
        .error$ = "Respondent influence needs at least 3 complete "
        ... + "respondents (leave-one-out on fewer would rest on a "
        ... + "single row); " + string$ (.nRowsIn) + " arrived and "
        ... + string$ (.n) + " remained after listwise deletion."
    else
        # --- Original-row mapping for the surviving rows ---
        .rowTotalIn# = rowSums# (.data##)
        .j = 0
        for .i from 1 to .nRowsIn
            if .rowTotalIn# [.i] <> undefined
                .j = .j + 1
                .rowIndex# [.j] = .i
            endif
        endfor

        # --- Center per column before any variance ---
        # Same conditioning guard as @emlCronbachAlpha: the downdate
        # formulas below run on sums of squares, which cancel
        # catastrophically under a large common offset. Centering by
        # the full-sample column means leaves every variance — full
        # and leave-one-out — unchanged.
        .rawColSum# = columnSums# (.work##)
        .ones# = zero# (.n) + 1
        .work## = .work## - outer## (.ones#, .rawColSum# * (1 / .n))

        # --- Full-sample sums (vectorized) ---
        .colSum# = columnSums# (.work##)
        .colSumSq# = columnSums# (.work## * .work##)
        .total# = rowSums# (.work##)
        .totSum = sum (.total#)
        .totSumSq = sum (.total# * .total#)

        # --- Full complete-case alpha ---
        .dfRows = .n - 1
        .itemVar# = (.colSumSq# - .colSum# * .colSum# / .n) / .dfRows
        .varTotal = (.totSumSq - .totSum * .totSum / .n) / .dfRows

        if .varTotal <= 0
            .error$ = "The total score has zero variance; "
            ... + "alpha is undefined."
        else
            .alphaFull = (.k / (.k - 1))
            ... * (1 - sum (.itemVar#) / .varTotal)

            # --- Jackknife: downdate the sums per respondent ---
            .m = .n - 1
            for .j from 1 to .n
                .rowVec# = row# (.work##, .j)
                .colSumJ# = .colSum# - .rowVec#
                .colSumSqJ# = .colSumSq# - .rowVec# * .rowVec#
                .totJ = .totSum - .total# [.j]
                .totSqJ = .totSumSq - .total# [.j] * .total# [.j]
                .itemVarJ# = (.colSumSqJ# - .colSumJ# * .colSumJ# / .m)
                ... / (.m - 1)
                .varTotalJ = (.totSqJ - .totJ * .totJ / .m) / (.m - 1)
                if .varTotalJ > 0
                    .alphaWithout# [.j] = (.k / (.k - 1))
                    ... * (1 - sum (.itemVarJ#) / .varTotalJ)
                    .delta# [.j] = .alphaWithout# [.j] - .alphaFull
                endif
            endfor

            # --- Largest absolute delta, reported by ORIGINAL row ---
            for .j from 1 to .n
                if .delta# [.j] <> undefined
                    .absDelta = abs (.delta# [.j])
                    if .deltaMax = undefined or .absDelta > .deltaMax
                        .deltaMax = .absDelta
                        .deltaMaxRow = .rowIndex# [.j]
                    endif
                endif
            endfor
        endif
    endif
endproc

# ============================================================================
# @emlSurveyValidateDeclaration
# ============================================================================
# Checks a survey declaration against the data it describes, before any
# reliability number is computed. The declaration is two small Tables (read
# from the two CSVs at evidence/csv/lane_survey_declared_SCHEMA.md's format
# -- a caller with a path just needs two "Read Table from comma-separated
# file..." lines, so no reader procedure lives here):
#
#   .scalesTableId - one row per subscale: columns "scale", "min", "max",
#                    "type" ("ordinal" or "continuous")
#   .itemsTableId  - one row per data column: columns "item", "role" (a
#                    scale name, "grouping", or "ignore"), "reversed" (0/1)
#
# against the data itself:
#
#   .dataTableId   - one row per respondent, one column per question
#
# Sixteen refusals. The first one found wins and stops the checks that
# follow it. Refusals 1-5 are Ian's original plan (SURVEY_MODULE_PLAN_2026-
# 08-25.md, "The validator"); refusals 6-9 are four ways the verification
# pass proved a declaration passes all five while leaving Stage 2's routing
# unsafe, each independently probed against Praat 6.6.30 and approved by
# Ian; refusal 10 is a contract repair to refusal 2, not a new probed hole,
# flagged as such where it is checked below -- it is Ian's to veto. Refusals
# 11-14 are a second adversarial pass's finding that the class of fault
# refusals 6-10 closed on the ITEMS file was never closed on the SCALES
# file: a missing required column halted Praat outright, and a non-numeric
# or missing declared min/max endpoint validated clean, on the scales file
# specifically (the items file's own required columns and its "reversed"
# and duplicate-name checks already existed). Refusals 15-16 (V1.5) are a
# third adversarial pass's finding that the DATA table itself was held to
# no standard at all: its own column labels were never checked for
# uniqueness, and it was never checked against the items file in the
# items-to-data direction refusal 1 does not cover.
#
#   1. An item names a column the data table does not have.
#   2. A data value falls outside its subscale's declared range. A MISSING
#      cell is not out of range -- listwise deletion handles it later, and
#      this refusal must not fire on it.
#   3. A subscale has fewer than two items.
#   4. An item declared "grouping" or "ignore" has reversed set to 1.
#   5. The scales file and the items file disagree on subscale names, in
#      EITHER direction: an item names a scale the scales file lacks, or a
#      declared scale has no item using it.
#   6. An item's `reversed` holds a value other than 0 or 1. The refusal 4
#      guard below reads "if .itemReversed[.i] = 1", true only for the
#      legal "reversed" value, so anything else passes it silently and is
#      treated as not-reversed with no disclosure.
#   7. An item name is declared more than once in survey_items.csv. Without
#      this, Stage 2 would read that column into its subscale twice -- once
#      forward, once reversed if so declared -- inflating k and injecting a
#      perfectly anti-correlated pair.
#   8. An item resolved to a subscale has an unusable data column: any of
#      @emlAuditColumn's kinds 2 (locale-comma), 4 (coerced), or 5
#      (leading-dot), or a kind-3 ("unreadable") cell that is NOT a
#      recognised missing-value placeholder -- every kind except 1
#      (genuinely empty), which stays exempt as ordinary missingness.
#      Refusal 2's range check reads the same cell through plain
#      "Get value:", which returns undefined for a non-numeric cell
#      exactly as it does for a genuinely missing one, and silently
#      MISREADS a locale-comma or leading-dot cell as a different number
#      rather than dropping it, so a corrupted or wrong-typed column (e.g.
#      a scale item mistakenly pointed at a free-text column, or a decimal
#      comma from a non-English locale) sails through refusal 2 undetected
#      or misread, and the kernel then either blames the sample size or
#      silently computes a wrong statistic for what is really a
#      declaration or data-entry fault. V1.4 widened this from kind 3
#      alone (Finding 1: refusal 8 was consuming only one fifth of
#      @emlAuditColumn's verdict on the exact call that decides it).
#
#      [V1.7, THE SUPERSEDING CELL RULING] Before this, refusal 8 refused
#      on EVERY kind-3 ("unreadable") cell with no further question asked
#      -- including a cell reading "na", "n/a", or any other spelling
#      @emlRepairClassify (eml-extract.praat:2665) already recognises as a
#      missing-value placeholder. That is superseded: a cell matching
#      @emlRepairClassify's own kind-3 list is no longer refused here. It
#      is treated as ordinary missingness -- listwise deletion handles it
#      exactly as a blank cell -- and its presence is disclosed instead
#      (.disclosureCount / .disclosureSpelling$[] / .disclosureItem$[] /
#      .disclosure$, a pass that runs BEFORE this refusal's own cascade
#      and is never skipped by a `goto`, documented at this procedure's
#      own Outputs header, below). Any OTHER kind-3 cell -- one
#      @emlRepairClassify does not recognise either -- still refuses here,
#      unchanged in effect, now also routing the user by name to
#      "Check & repair data" (Objects > New > EML Stats & Graphs > Check &
#      repair data...), which already lists and can fix cells like it; no
#      second inventory of every bad cell is built here. A whitespace-only
#      data cell is the one case deliberately NOT reclassified as a
#      placeholder yet: @emlRepairClassify does not itself fold whitespace
#      into kind 3 (a filed fix in the other lane, not yet landed), so it
#      stays under this refusal's existing Fix 3 pre-check, unchanged,
#      until that fix lands and this procedure's consumption of
#      @emlRepairClassify's whole verdict picks the change up with no
#      further edit needed here.
#   9. A scale's `type` is neither "ordinal" nor "continuous". The scales
#      read loop never read the type column before V1.2; Stage 2 branches
#      on it to choose the ordinal-as-interval disclosure line and would
#      print the wrong one, or none, on anything else.
#  10. [CONTRACT REPAIR, not a new probed hole -- Ian's to veto] A scale's
#      declared minimum is not below its declared maximum. Before this,
#      swapped endpoints (e.g. min 5, max 1) reached refusal 2 first, which
#      then named a RESPONDENT ROW with a remedy to check that row's data --
#      sending the user to inspect clean data when the fault is the
#      declaration's own transposed pair. An inverted range is a fault in
#      the declaration itself, not in any respondent's answer, so it must
#      be caught before any respondent row is examined.
#  11. A required column ("item", "role", "reversed" in survey_items.csv;
#      "scale", "min", "max", "type" in survey_scales.csv) is missing from
#      its file. Before this, a bare "Get value:" on a missing column
#      HALTED Praat outright (proved live: a three-column "scale,min,max"
#      scales file, the shape every declaration written before V1.2 has,
#      aborts with "Error: Table ... there is no column named ""type""")
#      instead of producing one of these fourteen refusals. Checked before
#      ANYTHING else in this procedure touches either table -- including
#      the array-population loops immediately below, which are what would
#      otherwise halt.
#  12. A subscale's declared `min` or `max` is missing or not numeric.
#      Before this, "Get value:" returns `undefined` for a non-numeric or
#      empty cell, and every guard that reads it -- refusal 10's
#      ".scaleMin[.s] >= .scaleMax[.s]" and refusal 2's range comparison --
#      is FALSE against `undefined` on either side, so both silently
#      disabled (proved live: "Confidence,one,5,ordinal" returns refusal =
#      0, and Stage 2 would then compute every reverse-scored value in the
#      subscale as `undefined + max - x`). Checked before refusal 10, which
#      depends on it.
#  13. A scale name is declared more than once in survey_scales.csv.
#      Refusal 2's resolution loop assigns `.sMin` / `.sMax` on every
#      matching row with no break, so a duplicate silently makes the LAST
#      matching row win (proved live: "Confidence,1,5,ordinal" and
#      "Confidence,1,200,ordinal" both present returns refusal = 0 against
#      a planted 99). Refusal 7 already refuses exactly this fault in the
#      items file; this is its analogue for the scales file, and shares
#      its scan (@eml_findDuplicateName, below).
#  14. A scale name is empty. Unchecked by the same gap as 13: an empty
#      name is never matched against a data column the way an item name
#      is (refusal 1), so nothing else in this procedure would ever catch
#      it.
#  15. [V1.5] Two of the data table's own columns share the same header
#      label. "Get column index:" and "Get value:" both resolve to the
#      FIRST match against a duplicated header, so refusal 1's lookup and
#      every per-row read after it (refusals 2 and 8) silently address
#      only the first column, and anything wrong in a later, shadowed
#      column of the same name is never seen at all.
#  16. [V1.5] A data-table column is not named by any row in
#      survey_items.csv. Refusal 1 already refuses the opposite direction
#      (an item names a column the data lacks); nothing before this
#      checked that every data column is, in turn, accounted for --
#      scored by a subscale item, or explicitly marked "grouping" or
#      "ignore". A column present only in the data table is silently
#      neither.
#  17. [Stage 3 ruling] Two scale names collide once spaces are converted
#      to underscores. A subscale name is a DISPLAY name and may contain
#      spaces (item 4 of the ruling); the plugin's scores-table columns,
#      CSV headers and file stems all use the underscore-normalized form
#      instead, so "Vocal Health" and "Vocal_Health" -- distinct, and
#      both legal under refusal 13 alone -- collide the moment either one
#      becomes an identifier. Checked right after refusal 13 (raw-name
#      duplication): by construction every raw name is already unique by
#      the time this runs, so any collision found here is necessarily
#      between two DIFFERENT raw spellings, never the same fault refusal
#      13 already reports.
#
# ORDERING, why refusals 6, 7, 9, 10 sit before 2 and 8 rather than after
# 5, and why 11-14 sit where they do: 6, 7, 9, 10, 11, 12, 13, 14 and 17
# are ALL faults in the declaration ITSELF -- each is decided from
# survey_items.csv or survey_scales.csv alone, with no data Table read at
# all -- while 2 and 8 both read every respondent's data. A declaration
# fault must be reported before any data-reading refusal has a chance to
# misreport it (refusal 10's whole reason for existing), so the checked
# order is: 11, 1, 7, 6, 14, 13, 17, 12, 9, 10, 8, 2, 3, 4, 5. Refusals 15
# and 16 (V1.5) are the one exception to "declaration faults before data
# faults": both are facts about the DATA table itself, but both are more
# basic than refusal 1 -- 15 because a duplicated header makes refusal 1's
# own lookup unreliable (it would silently resolve to the first of the
# two and report nothing wrong), and 16 because it is refusal 1's mirror
# question about the same table, asked right alongside it. Checked order
# is therefore: 11, 15, 1, 16, 7, 6, 14, 13, 17, 12, 9, 10, 8, 2, 3, 4, 5.
# Refusal 11 comes first of all, ahead even of refusal 1: it is the one
# check that must run before the items- and scales-array population loops
# themselves, which read every required column with a bare "Get value:"
# and would otherwise
# be the thing that halts. Within the remaining declaration-shape faults,
# the items-table checks (7, 8's precondition aside, then 6) run before
# the scales-table checks (14, 13, 12, 9, 10) because the items table is
# the one read first, above; 7 (no item name repeated) runs before 6 (each
# `reversed` value is legal) because a row's own name is the more basic
# fact about it, and the same reasoning orders the scales-table checks: 14
# (a scale has a name at all) before 13 (that name is not repeated) before
# 12 (its declared range is usable) before 9 (its declared type is legal)
# before 10 (its range is not transposed) -- each a more basic fact about
# a scale than the one that follows it, and 12 specifically must precede
# 10 because 10 reads exactly the two values 12 confirms are usable. This
# reordering only inserts new checks -- it does not alter what refusals
# 1-5 individually decide, so a fixture that seeds exactly one of the
# original five defects (and nothing from 6, 7, 9, 10, 11, 12, 13, 14)
# still resolves to that same original code; validate/v129_survey_
# declaration.R keeps every refusal-1-through-5 leg passing unchanged.
#
# Refusal 1 is checked before refusal 2 for a reason beyond the plan's
# ordering: refusal 2's range check reads every item's data column by name,
# and it can only do that safely once refusal 1 has confirmed every item
# names a real column. By the time refusal 2's loop runs, that precondition
# already holds.
#
# ----------------------------------------------------------------------------
# @eml_underscoreNormalize
# Internal helper (Stage 3 ruling, item 4): the FORWARD half of the
# plugin's display-name <-> identifier pairing -- spaces to underscores,
# for turning a display name (may contain spaces, e.g. a subscale name
# "Vocal Health") into the identifier form the plugin's scores-table
# columns, CSV headers and file stems use ("Vocal_Health"). The REVERSE
# direction already has a name and a home, @emlUnderscoreToSpace
# (stats/eml-output.praat:163, underscore to space, for DISPLAY); the
# forward direction had none -- it is written inline, twice, in
# graphs/eml-graphs-form.praat (lines 1396 and 10743, both a bare
# `replace$ (x, " ", "_", 0)`), a file this lane may read but not edit.
# This procedure is Ian's ruling applied on this lane's own side of that
# boundary: the SAME one-line transform, named once, so every caller in
# this module's reach (refusal 17's collision check, below, and anything
# scores-table/CSV/file-stem-shaped that follows it) shares one
# declaration instead of a third inline copy. It does not touch or
# replace the graphs-form file's own two copies -- extracting THOSE into
# a shared procedure is filed for whoever owns that file, not done here.
#
# validate/v129_survey_declaration.R's parity check reads all three
# copies -- this procedure's own body, and the two literal sites in
# graphs/eml-graphs-form.praat -- from their own source, and asserts all
# three transform the same probe strings identically, so the three can
# never quietly drift apart.
#
# Input:  .text$
# Output: .result$ - .text$ with every space converted to an underscore
# ----------------------------------------------------------------------------
procedure eml_underscoreNormalize: .text$
    .result$ = replace$ (.text$, " ", "_", 0)
endproc

# ----------------------------------------------------------------------------
# @eml_findDuplicateName
# Internal helper: shared duplicate-name scan for a declaration file's own
# name column -- survey_items.csv's "item" (refusal 7) and
# survey_scales.csv's "scale" (refusal 13) ask the SAME question of two
# different tables/columns, so this is that question, asked once, rather
# than the same nested loop written out twice.
#
# A later duplicate is reported by ITS OWN row number: the first
# occurrence is not itself wrong, so naming the second occurrence names
# the row to delete. Reports only the FIRST duplicated name found,
# scanning in row order, matching refusal 7's pre-existing behavior
# exactly (a table with more than one duplicated name reports the
# earliest one).
#
# .normalize (Stage 3 ruling, refusal 17): 0 compares raw cell text, exactly
# the original behavior refusals 7/13/15 still use (their three call sites
# now pass 0 explicitly). 1 compares each name through
# @eml_underscoreNormalize first -- refusal 17's own question, "do two
# subscale names collide once spaces become underscores" -- WITHOUT
# touching the comparison line itself (still bare "if .jName$ = .iName$",
# unchanged text and indentation, so the negative control seeded against
# THAT line for refusals 7/13/15 keeps testing the same guard it always
# did): .iName$/.jName$ are normalized in place, ahead of the comparison,
# only when .normalize = 1; .iRaw$/.jRaw$ keep the untouched cell text
# alongside, so a normalized COLLISION between two DIFFERENT raw spellings
# (".rawName1$" / ".rawName2$") can still be named in a message -- unlike a
# raw duplicate, where the two spellings are identical and one name is
# enough.
#
# Input:  .tableId, .columnName$, .nRows, .normalize
# Output: .found     - 1 if some (possibly normalized) name repeats, 0 otherwise
#         .name$     - the first occurrence's RAW text (only meaningful when
#                       .found = 1; equals .rawName1$)
#         .rawName1$ - the first occurrence's RAW text
#         .rawName2$ - the duplicate's RAW text (identical to .rawName1$
#                       when .normalize = 0; may differ when .normalize = 1
#                       and it was the normalized forms that collided)
#         .firstRow  - row of the first occurrence
#         .dupRow    - row of the duplicate (the later occurrence)
# ----------------------------------------------------------------------------
procedure eml_findDuplicateName: .tableId, .columnName$, .nRows, .normalize
    .found = 0
    .name$ = ""
    .rawName1$ = ""
    .rawName2$ = ""
    .firstRow = 0
    .dupRow = 0
    for .i from 1 to .nRows
        selectObject: .tableId
        .iName$ = Get value: .i, .columnName$
        .iRaw$ = .iName$
        if .normalize = 1
            @eml_underscoreNormalize: .iName$
            .iName$ = eml_underscoreNormalize.result$
        endif
        for .j from .i + 1 to .nRows
            selectObject: .tableId
            .jName$ = Get value: .j, .columnName$
            .jRaw$ = .jName$
            if .normalize = 1
                @eml_underscoreNormalize: .jName$
                .jName$ = eml_underscoreNormalize.result$
            endif
            if .jName$ = .iName$
                if .found = 0
                    .found = 1
                    .name$ = .iRaw$
                    .rawName1$ = .iRaw$
                    .rawName2$ = .jRaw$
                    .firstRow = .i
                    .dupRow = .j
                endif
            endif
        endfor
    endfor
endproc

# ----------------------------------------------------------------------------
# @eml_findWhitespaceOnlyCell (V1.6, Fix 2)
# Internal helper: is any cell of a column whitespace-only text -- non-empty
# exactly as Praat's Table stores it, but empty once trimmed?
#
# WHY THIS EXISTS. @eml_strictNumericColumn (eml-extract.praat)'s own
# pre-scan, run before its fast path hands a whole column to Praat's own
# "Get all numbers in column:", recognises only three spellings of
# "unreadable": "", "--undefined--", and "?". A cell holding nothing but a
# space matches none of the three, so the fast path proceeds and Praat
# itself halts -- proved live on a scales file reading
# "Confidence, ,5,ordinal": "Table ...: the cell in row 1 of column ""min""
# is undefined ... cannot get all numbers in column 2" -- instead of any of
# this module's own refusals ever getting a chance to fire.
# eml-extract.praat is outside this lane's boundary, so the fix lives here
# instead, with @eml_classifyCell -- the classifier this module already
# calls for exactly this kind of question (it trims before testing, and
# already folds a whitespace-only cell into kind 1, "empty", alongside ""
# and "--undefined--") -- not a second, narrower reimplementation of what
# "unreadable" means.
#
# Called BEFORE @emlRequireNumericColumn / @emlAuditColumn ever see a
# column, on "min" and "max" alike: calling either on a column already
# carrying this landmine cell IS the crash, not a defence against it, so
# there is no error output here to consume -- there is nothing left to ask
# once this has already returned .found = 1 for that column.
#
# THE SKIP CONDITION, AND WHY IT IS NOT THE SAME LIST TWICE (Fix 3). The
# previous round's skip re-typed all three of @eml_strictNumericColumn's
# spellings ("", "--undefined--", "?") -- one canon, stated in two files,
# with nothing holding the copies together. Checked here: @eml_classifyCell
# never returns kind 1 for a bare "?" (it is not empty once trimmed, and it
# is not a number in any locale -- @eml_classifyCell's own kind 3), so the
# "?" comparison below never once changed which row this loop reports; it
# was dead. The other two are NOT dead -- they are load-bearing, and for a
# reason specific to THIS helper rather than to the pre-scan it is patching
# a gap in: a caller auditing a DATA column (as opposed to a "min"/"max"
# endpoint) must tell an outright empty cell ("" or the round-tripped
# "--undefined--" token) apart from a whitespace-only one, because the
# first is ordinary missingness -- exempt, per this module's own refusal 8
# -- and the second is not. Folding either spelling into "whitespace-only
# found" here would misreport an exempt, genuinely missing cell as the
# crash-landmine this helper exists to catch. So the two that still do
# something stay, spelled out in full rather than as a fragment of the
# three; v129_survey_declaration.R checks by source text (the
# v105_pitch_parity.R pattern: the canon is read out of both files and
# compared, not restructured into one) that this pair is still a subset of
# @eml_strictNumericColumn's own list, so the two cannot silently drift
# apart if that list ever changes.
#
# Input:  .tableId, .columnName$, .nRows
# Output: .found - 1 if some cell is whitespace-only, 0 otherwise
#         .row   - the first such row (only meaningful when .found = 1)
# ----------------------------------------------------------------------------
procedure eml_findWhitespaceOnlyCell: .tableId, .columnName$, .nRows
    .found = 0
    .row = 0
    for .i from 1 to .nRows
        selectObject: .tableId
        .raw$ = Get value: .i, .columnName$
        ; Skip a cell that is already one of @eml_classifyCell's own kind-1
        ; spellings for "genuinely nothing here" ("" or "--undefined--") --
        ; those are safe downstream (ordinary missingness) and are not this
        ; helper's question. The "?" spelling @eml_strictNumericColumn's own
        ; pre-scan also treats as unreadable is NOT tested here: it never
        ; classifies as kind 1 in the first place (see header comment above),
        ; so testing for it here would only restate a token this loop can
        ; never actually match.
        if .raw$ <> "" and .raw$ <> "--undefined--"
            @eml_classifyCell: .raw$
            if eml_classifyCell.kind = 1
                if .found = 0
                    .found = 1
                    .row = .i
                endif
            endif
        endif
    endfor
endproc

# ----------------------------------------------------------------------------
# @eml_scanColumnForPlaceholders (V1.7)
# Internal helper: THE SUPERSEDING CELL RULING's own classifier composition,
# in one place, called once per subscale item's data column.
#
# @emlAuditColumn (eml-extract.praat) sorts every cell of a column into
# kinds 0 (valid), 1 (empty), 2 (locale-comma), 4 (coerced), 5 (leading-dot),
# or its "else" bucket -- everything @eml_classifyCell cannot place in the
# first five, which this module has always called "unreadable". Refusal 8
# used to refuse on every cell in EITHER of those two buckets (its own
# "else" bucket, and kind 5), with no further question asked of either.
# The cell ruling says a cell whose text is one of @emlRepairClassify's OWN
# kind-3 missing-value spellings (na, n/a, n.a., nan, null, nil, -, --, .,
# ?, missing -- case-insensitive; that list lives ONLY at @emlRepairClassify,
# eml-extract.praat:2665, and is not restated here) is a recognised
# placeholder, not a wrong answer, and is treated as ordinary missingness;
# any other cell in either bucket is still genuinely unreadable and still
# refuses. This helper answers, for one column, which cells are which -- it
# does not itself refuse or disclose anything; the caller
# (@emlSurveyValidateDeclaration) does both, in two separate passes, below.
#
# BOTH kind 5 and the "else" bucket are examined here, not just the
# "else" bucket, because the authority is @emlRepairClassify's kind-3 list,
# and @eml_classifyCell's OWN kind assignment is not a safe proxy for it: a
# bare "." is one of the eleven authority spellings, but @eml_classifyCell's
# leading-dot recovery (built for ".5") treats it exactly like a ".5" and
# files it as kind 5, "recoverable", never reaching the "else" bucket at
# all. Excluding kind 5 from this scan (an earlier version of this helper
# did) meant every "." placeholder skipped @emlRepairClassify entirely and
# fell through to refusal 8's kind-5 handling as if it were a genuine
# leading-dot VALUE -- refused as unusable, disclosureCount 0, exactly the
# defect the cell ruling exists to close. So every cell @eml_classifyCell
# calls kind 5 is asked here too, on the same terms as the "else" bucket:
# @emlRepairClassify's real verdict decides placeholder-or-not, never
# @eml_classifyCell's kind by itself. A genuine leading-dot value like
# ".5" or "-.7" is unaffected -- @emlRepairClassify's own kind for those is
# 2 ("bare leading point", not 3), so they fall to .firstGenuineBadRow
# exactly as before, and refusal 8 still refuses on them.
#
# Kinds 0, 1, 2 and 4 of @eml_classifyCell are NOT examined here -- they
# keep whatever handling refusal 8 already gives them elsewhere in this
# module, untouched by the cell ruling, which is only about the two
# unusable buckets (kind 5, and "else"). Within those buckets, every
# @emlRepairClassify kind OTHER than 3 (0 "nothing recognised", 2 "bare
# leading point" -- what a genuine kind-5 cell itself always reports -- or
# the rarer 1/4 a comma- or percent-bearing piece of otherwise-unreadable
# text can still trigger, e.g. "approx,4") is treated alike, as NOT a
# recognised placeholder: only kind 3 is the ruling's stated authority, and
# a cell @eml_classifyCell already could not read as a plain number does
# not become one just because @emlRepairClassify also notices a stray
# comma in it. Whole verdict consumed, two kinds excluded, stated here.
#
# Whitespace-only cells are the one case deliberately NOT reached by the
# placeholder branch below, and deliberately not specially handled here
# either: @eml_classifyCell already folds a whitespace-only cell into kind
# 1 ("empty", the same bucket a genuinely blank cell falls into), so it
# never reaches the "unreadable" test at all and this helper never asks
# @emlRepairClassify about it. That is exactly today's classifier
# behaviour kept as the cell ruling requires -- @emlRepairClassify itself
# does not yet fold whitespace into its own kind 3 (a filed, not yet
# landed, fix in the other lane) -- so whitespace-only data cells stay
# under refusal 8's existing @eml_findWhitespaceOnlyCell pre-check, below,
# entirely unchanged, rather than being pulled into this helper's question
# ahead of that fix actually landing.
#
# Reads every row with a plain "Get value:", never "Get all numbers in
# column:" -- so, like @eml_findWhitespaceOnlyCell above, it is safe to
# run on a column that already carries the whitespace-only landmine cell
# Fix 3 exists to route around, without needing that pre-check itself
# first.
#
# Input:  .tableId, .columnName$, .nRows
# Output: .nPlaceholder                     - count of recognised
#                       missing-value placeholder cells in this column
#         .placeholderRow[1..nPlaceholder]      - each one's row number
#         .placeholderText$[1..nPlaceholder]    - each one's raw text,
#                       trimmed (@eml_classifyCell's .trimmed$)
#         .firstGenuineBadRow    - first row whose text is unreadable AND
#                       not a recognised placeholder; 0 if none
#         .firstGenuineBadText$  - that row's raw text, trimmed; "" if
#                       .firstGenuineBadRow is 0
# ----------------------------------------------------------------------------
procedure eml_scanColumnForPlaceholders: .tableId, .columnName$, .nRows
    .nPlaceholder = 0
    .firstGenuineBadRow = 0
    .firstGenuineBadText$ = ""

    # FAST PATH, same shape as @emlAuditColumn's own (eml-extract.praat) --
    # the plugin's existing whole-column numeric machinery, called, not
    # reimplemented. @eml_strictNumericColumn answers, for the WHOLE
    # column in one pass (one probe Table, one "Get all numbers in
    # column:", not one scratch Table per cell), whether "Get all numbers
    # in column:" would return the column's real values rather than
    # alphabetical ranks (.strict = 1) and whether every cell is even
    # present (.unreadable = 0 -- "", "--undefined--" and "?" all set it).
    # .strict can only be 1 when .unreadable is already 0 (the sentinel
    # check inside @eml_strictNumericColumn does not run otherwise), so
    # both are tested here only for readability, matching
    # @emlAuditColumn's own two-flag test rather than inventing a
    # one-flag shortcut nothing else in the file uses.
    #
    # .strict = 1 means EVERY cell independently parses as a plain,
    # locale-free number: a single comma, percent sign, bare leading dot,
    # placeholder spelling or any other non-numeric text anywhere in the
    # column drags the whole-column read down to ranks (see
    # @emlCommaColumnMode's header for the measured comma case; the same
    # rank-corruption applies to any cell "Get all numbers in column:"
    # cannot parse), which @eml_strictNumericColumn's own sentinel-row
    # check exists to detect. So .strict = 1 is exactly "every cell is
    # @eml_classifyCell's kind 0" for this column -- no placeholder, no
    # genuinely bad cell, nothing the loop below would find -- and the
    # per-cell loop, with its per-cell scratch Table, is skipped entirely.
    #
    # GUARDED FIRST AGAINST THE SAME WHITESPACE LANDMINE Fix 3 (refusal 8,
    # below) already routes around: @eml_strictNumericColumn's own
    # unreadable pre-scan recognises only "", "--undefined--" and "?" --
    # not a cell holding nothing but spaces or tabs -- so handing it a
    # column that carries one reaches Praat's own "Get all numbers in
    # column:" unguarded, which HALTS the whole script outright rather
    # than returning a verdict (verified live: a single space in an
    # otherwise-clean column aborts with "the cell in row N of column
    # ...  is undefined", before this procedure ever gets to report
    # anything). Fix 3's own guard, @eml_findWhitespaceOnlyCell, is not
    # reused here for that: it calls @eml_classifyCell per cell, the exact
    # per-cell-scratch-Table cost this fast path exists to skip, so
    # reusing it would pay the whole thing back on every column, clean or
    # not. What is needed here is only ONE bit -- does this column contain
    # ANY whitespace-only cell -- so it is answered with the same trim
    # @emlRepairClassify itself trims with (eml-extract.praat, "^[ \t]+|
    # [ \t]+$"), a plain string operation, no Table involved: cheap enough
    # to run on every column while still skipping the expensive path for
    # every column that turns out clean.
    .wsGuardFound = 0
    .wsGuardRow = 1
    while .wsGuardFound = 0 and .wsGuardRow <= .nRows
        selectObject: .tableId
        .wsGuardRaw$ = Get value: .wsGuardRow, .columnName$
        if .wsGuardRaw$ <> "" and .wsGuardRaw$ <> "--undefined--"
            .wsGuardStripped$ = replace_regex$ (.wsGuardRaw$, "^[ \t]+|[ \t]+$", "", 0)
            if .wsGuardStripped$ = ""
                .wsGuardFound = 1
            endif
        endif
        .wsGuardRow = .wsGuardRow + 1
    endwhile

    if .wsGuardFound = 0
        @eml_strictNumericColumn: .tableId, .columnName$
        if eml_strictNumericColumn.strict = 1 and eml_strictNumericColumn.unreadable = 0
            goto SCAN_COLUMN_DONE
        endif
    endif

    for .i from 1 to .nRows
        selectObject: .tableId
        .raw$ = Get value: .i, .columnName$
        @eml_classifyCell: .raw$
        if eml_classifyCell.kind <> 0 and eml_classifyCell.kind <> 1
        ... and eml_classifyCell.kind <> 2 and eml_classifyCell.kind <> 4
            @emlRepairClassify: .raw$
            if emlRepairClassify.kind = 3
                .nPlaceholder = .nPlaceholder + 1
                .placeholderRow[.nPlaceholder] = .i
                .placeholderText$[.nPlaceholder] = eml_classifyCell.trimmed$
            elsif .firstGenuineBadRow = 0
                .firstGenuineBadRow = .i
                .firstGenuineBadText$ = eml_classifyCell.trimmed$
            endif
        endif
    endfor

    label SCAN_COLUMN_DONE
endproc

# THE TEACHING-MESSAGE CONTRACT (docs/CHANGE_ORDER_CONFORMANCE_LINT.md): the
# rule in one sentence, the reason in one line, what to do instead. The rule
# and the reason are assembled into .error$; the fix is .remedy$, kept as
# its own output so a caller can show it separately (a dialog action line,
# a CSV note) without parsing a sentence for it.
#
# ----------------------------------------------------------------------------
# DRAFT LANGUAGE -- awaiting Ian's approval (language section, plan p.159).
# Every fragment below is user-facing wording, not logic. All five are
# collected in this one block, in refusal order, so approved wording drops
# in by editing these fragments alone; nothing below this block should need
# to change when it does. Each fragment is a literal piece of the sentence;
# the check sites concatenate them around the item/scale/row/value in
# question with "+". Every fragment is plain ASCII (CLAUDE.md: any string
# literal that can reach a file must be).
# ----------------------------------------------------------------------------
procedure emlSurveyValidateDeclaration: .dataTableId, .scalesTableId, .itemsTableId
    # --- Outputs: initialize before any check runs ---
    .error$ = ""
    .remedy$ = ""
    .refusal = 0
    .badItem$ = ""
    .badScale$ = ""
    .badRow = 0
    .badValue = undefined
    .badMin = undefined
    .badMax = undefined
    .scaleItemCount = undefined
    .badRole$ = ""
    .badDirection$ = ""
    ; V1.2 additions (refusals 6-10) below. .badItem$, .badScale$ and
    ; .badRow above are reused where they already say the right thing
    ; (refusals 6-8 name an item, 9-10 name a scale, 8 names a data row);
    ; these four are the fields those five refusals need and nothing above
    ; already carries.
    .badReversedValue = undefined
    .badItemRow = 0
    .badScaleRow = 0
    .badTypeValue$ = ""
    .badCellText$ = ""
    ; V1.3 additions (refusals 11-14) below.
    .badColumn$ = ""
    .badFile$ = ""
    .badRawValue$ = ""
    ; V1.7 addition (cell ruling, branches 1/2): seeded here, ahead of
    ; every refusal, for the same reason as everything above -- the
    ; disclosure pass that sets these for real does not run until after
    ; refusals 11, 15, 1, 16, 7, 6, 14, 13, 12 and 10 have all already
    ; passed, so any of THEIR exits would otherwise leave these four
    ; undefined.
    .disclosureCount = 0
    .disclosureSpellingCount = 0
    .disclosureItemCount = 0
    .disclosure$ = ""
    ; .disclosureSpelling$[] / .disclosureItem$[] are INDEXED outputs, so
    ; the same halt V1.6 Fix 1 closed for the five per-scale arrays
    ; applies here too (CLAUDE.md: reading an unassigned indexed variable
    ; HALTS) -- but unlike .nScales, the real length of these two is not
    ; knowable this early (it depends on what the data actually holds, not
    ; on a row count "Get number of rows" can supply up front). Index 1
    ; alone is seeded to a defined placeholder ("", meaning "no
    ; placeholder found") because that is the one index
    ; validate/v129_survey_declaration.R's exhaustive output-contract
    ; sweep (Fix 1) reads on every leg, including the many that plant no
    ; placeholder at all; the disclosure pass below overwrites it with the
    ; real first spelling/item only when one is actually found.
    .disclosureSpelling$[1] = ""
    .disclosureItem$[1] = ""

    # --- Canon keyword sets (V1.2), stated ONCE here -- every check below
    # that needs to know a legal `reversed` value or a legal `type` keyword
    # reads one of these, never a literal. (The pre-existing "grouping" /
    # "ignore" role literals in refusals 4 and 5 above are untouched V1.1
    # code and outside this addition's scope.)
    .reversedValueFalse = 0
    .reversedValueTrue = 1
    .typeKeywordOrdinal$ = "ordinal"
    .typeKeywordContinuous$ = "continuous"

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 1: item names a column the data table lacks.
    .msg1a$ = "Every item in survey_items.csv must name a column that "
    ... + "exists in the data table. Item """
    .msg1b$ = """ does not match any column header in the data table, "
    ... + "so there is nothing to read its responses from."
    .rem1$ = "Correct the item name in survey_items.csv to match the "
    ... + "data table's column header exactly, or delete this row if "
    ... + "the column no longer exists."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 2: a data value outside its subscale's declared range.
    .msg2a$ = "Every response must fall within its subscale's declared "
    ... + "range. Respondent row "
    .msg2b$ = ", item """
    .msg2c$ = """ (subscale """
    .msg2d$ = """), has the value "
    .msg2e$ = ", outside the declared range "
    .msg2f$ = " to "
    .msg2g$ = "."
    .rem2a$ = "Check respondent row "
    .rem2b$ = " for a data-entry error, or correct the declared range "
    ... + "for """
    .rem2c$ = """ in survey_scales.csv if the printed range was "
    ... + "mistyped."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 3: a subscale with fewer than two items.
    .msg3a$ = "Every subscale needs at least two items before its "
    ... + "reliability can be computed. Subscale """
    .msg3b$ = """ has "
    .msg3c$ = " item(s) declared."
    .rem3a$ = "Add another item with role """
    .rem3b$ = """ in survey_items.csv, or remove """
    .rem3c$ = """ from survey_scales.csv if it is meant to have only "
    ... + "one question."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 4: reversed set on a grouping or ignore column.
    .msg4a$ = "Only a scale item can be reverse-scored. Item """
    .msg4b$ = """ is declared """
    .msg4c$ = """ but has reversed set to 1."
    .rem4a$ = "Set reversed to 0 for """
    .rem4b$ = """ in survey_items.csv, or give it a subscale role if "
    ... + "it is meant to be scored."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 5, direction A: an item names a scale the scales file lacks.
    .msg5aA$ = "Every item's role must be a subscale declared in "
    ... + "survey_scales.csv, or the literal value grouping or ignore. "
    ... + "Item """
    .msg5aB$ = """ names """
    .msg5aC$ = """, which survey_scales.csv does not declare."
    .rem5aA$ = "Add a row for """
    .rem5aB$ = """ to survey_scales.csv, or correct the role for """
    .rem5aC$ = """ in survey_items.csv."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 5, direction B: a declared scale that no item uses.
    .msg5bA$ = "Every subscale in survey_scales.csv must be used by at "
    ... + "least one item. Subscale """
    .msg5bB$ = """ has no item declaring it as a role."
    .rem5bA$ = "Add an item with role """
    .rem5bB$ = """ in survey_items.csv, or remove """
    .rem5bC$ = """ from survey_scales.csv if it is not part of this "
    ... + "instrument."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 6: reversed holds a value other than 0 or 1.
    .msg6a$ = "reversed must be exactly 0 or 1; any other value is "
    ... + "silently treated as ""not reversed"" and the item stays "
    ... + "forward-scored with no disclosure. Item """
    .msg6b$ = """ has reversed set to "
    .msg6c$ = "."
    .rem6a$ = "Set reversed to 0 or 1 for """
    .rem6b$ = """ in survey_items.csv."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 7: an item name declared more than once.
    .msg7a$ = "Every item name in survey_items.csv must be unique. Item """
    .msg7b$ = """ is declared more than once; the second declaration is "
    ... + "row "
    .msg7c$ = "."
    .rem7a$ = "Remove the duplicate row for """
    .rem7b$ = """ in survey_items.csv, keeping only one."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 8: an item resolved to a subscale has a non-numeric data
    # column.
    .msg8a$ = "Every item scored as part of a subscale must hold numeric "
    ... + "responses. Item """
    .msg8b$ = """ (subscale """
    .msg8c$ = """) has an unusable value in respondent row "
    .msg8d$ = ": """
    .msg8e$ = """."
    .rem8a$ = "Correct or remove the unusable cell in column """
    .rem8b$ = """ (row "
    .rem8c$ = "), or change its role in survey_items.csv if the column "
    ... + "is not meant to be a scale item."
    ; V1.7, cell ruling branch 3: appended to EVERY refusal-8 remedy (both
    ; call sites share .rem8a$/.rem8b$/.rem8c$/.rem8d$, so this one
    ; addition reaches the whitespace-only pre-check below as well as the
    ; main unreadable-cell check, with nothing duplicated at either call
    ; site). This module builds no inventory of every bad cell in the
    ; Table -- that screen already lists and can fix every one of them;
    ; refusal 8 only ever needs to route there by name.
    ;
    ; STAGE 3 RULING (Ian, approved): exact wording, verbatim --
    ; "Run EML Stats & Graphs > Check & repair data, which lists and
    ; repairs all cells with error, then rerun". Names the same command
    ; and cascade setup.praat registers ("EML Stats & Graphs" the depth-0
    ; cascade header, "Check & repair data..." the depth-1 command), just
    ; without the "Objects > New >" prefix or the dialog-ellipsis, which
    ; belong to the menu chrome, not the sentence. The mechanism that
    ; holds this in agreement with setup.praat's own registration is
    ; validate/v132_survey_report_layer.R's eml_menu_canon: it reads
    ; setup.praat and derives the command label (with the trailing "..."
    ; stripped) and the "cascade > command" phrase this sentence uses,
    ; rather than a second copy of either typed into the check.
    .rem8d$ = " Run EML Stats & Graphs > Check & repair data, which lists "
    ... + "and repairs all cells with error, then rerun"

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Cell ruling, branch 2: the disclosure printed whenever ANY recognised
    # missing-value placeholder cell was found among the subscale items'
    # data columns (@eml_scanColumnForPlaceholders, above; the kind-3 list
    # it consumes lives only at @emlRepairClassify, eml-extract.praat:2665,
    # and is not restated here or in this sentence). One aggregated block,
    # not one line per item: the three facts required -- how many cells,
    # which spellings, which items -- are properties of the RUN, and
    # @emlAuditColumn's own .note$ (eml-extract.praat) already sets the
    # precedent of one block naming several kinds of altered cell rather
    # than one block per row. Whitespace-only cells are never named here
    # (see @eml_scanColumnForPlaceholders's own header on why) -- until the
    # filed classifier fix lands, this sentence may promise that it will,
    # but must not claim it already does.
    .msgDiscA$ = " cell(s) held a recognized missing-value placeholder "
    ... + "instead of a response, and were treated as missing data, "
    ... + "exactly like a blank cell -- not guessed at. Spelling(s) "
    ... + "found: "
    .msgDiscB$ = ". Item(s) affected: "
    .msgDiscC$ = ". (A whitespace-only cell is not yet included here; a "
    ... + "filed fix will add it once it lands. Until then it is refused "
    ... + "like any other unreadable cell, below.)"

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 9: a scale type that is neither ordinal nor continuous.
    .msg9a$ = "A subscale's type must be exactly ""ordinal"" or "
    ... + """continuous"". Subscale """
    .msg9b$ = """ declares type """
    .msg9c$ = """, which is neither."
    .rem9a$ = "Correct the type for """
    .rem9b$ = """ in survey_scales.csv to ordinal or continuous."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 10 [contract repair -- Ian's to veto]: a declared minimum
    # not below its declared maximum.
    .msg10a$ = "A subscale's declared minimum must be less than its "
    ... + "declared maximum. Subscale """
    .msg10b$ = """ declares min "
    .msg10c$ = " and max "
    .msg10d$ = ", which is not a valid range."
    .rem10a$ = "Check survey_scales.csv for """
    .rem10b$ = """: the min and max may be transposed."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 11: a required column is missing from either declaration
    # file.
    .msg11a$ = "Every column this validator depends on must be present. """
    .msg11b$ = """ has no column named """
    .msg11c$ = """."
    .rem11a$ = "Add a """
    .rem11b$ = """ column to """
    .rem11c$ = """, or restore it if it was removed by hand."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 12: a subscale's declared min or max is missing or not
    # numeric.
    .msg12a$ = "A subscale's declared min and max must both be numbers. "
    ... + "Subscale """
    .msg12b$ = """ declares """
    .msg12cText$ = """ as """
    .msg12dText$ = """, which is not a number."
    .msg12eEmpty$ = """ as empty, which is not a number."
    .rem12a$ = "Correct the """
    .rem12b$ = """ value for """
    .rem12c$ = """ in survey_scales.csv to a number."
    ; Finding 7's defensive fallback: the named column itself could not be
    ; read (unreachable today -- see the call site) so there is no scale
    ; name to report a row against.
    .msg12fCol$ = "A subscale's declared """
    .msg12gCol$ = """ column could not be read."
    .rem12dCol$ = "Check survey_scales.csv for a missing or misnamed """
    .rem12eCol$ = """ column."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 13: a scale name declared more than once.
    .msg13a$ = "Every subscale name in survey_scales.csv must be unique. "
    ... + "Subscale """
    .msg13b$ = """ is declared more than once; the second declaration is "
    ... + "row "
    .msg13c$ = "."
    .rem13a$ = "Remove the duplicate row for """
    .rem13b$ = """ in survey_scales.csv, keeping only one."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 14: a scale name is empty.
    .msg14a$ = "Every subscale in survey_scales.csv must have a name. Row "
    .msg14b$ = " has no scale name."
    .rem14a$ = "Add a scale name to the empty row in survey_scales.csv, "
    ... + "or delete the row if it is not a real subscale."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 15 [V1.5]: two data-table columns share the same header.
    .msg15a$ = "Every column in the data table must have a unique header. """
    .msg15b$ = """ is used by more than one column, so only the first one "
    ... + "can ever be read."
    .rem15a$ = "Rename or remove the duplicate """
    .rem15b$ = """ column so the data table's headers are unique."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 16 [V1.5]: a data-table column is not declared by any item.
    .msg16a$ = "Every column in the data table must be listed in "
    ... + "survey_items.csv. Column """
    .msg16b$ = """ is not."
    .rem16a$ = "Add a row for """
    .rem16b$ = """ to survey_items.csv (with role grouping or ignore if "
    ... + "it is not meant to be scored), or remove the column from the "
    ... + "data table if it should not be there."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 17 [Stage 3 ruling, item 5]: two subscale names collide once
    # spaces become underscores. Names BOTH raw spellings, since -- unlike
    # refusal 13 -- they are not identical text.
    .msg17a$ = "Every subscale name in survey_scales.csv must stay unique "
    ... + "once spaces are converted to underscores (the form scores-table "
    ... + "columns, CSV headers, and file stems use). Subscale """
    .msg17b$ = """ (row "
    .msg17c$ = ") and subscale """
    .msg17d$ = """ (row "
    .msg17e$ = ") both normalize to """
    .msg17f$ = """."
    .rem17a$ = "Rename """
    .rem17b$ = """ or """
    .rem17c$ = """ in survey_scales.csv so they no longer collide once "
    ... + "spaces become underscores."
    # ------------------------------------------------------------------------
    # END draft language block.
    # ------------------------------------------------------------------------

    # --- Normalize any quoted column headers before any table lookup ---
    # Praat's CSV reader strips quotes from quoted DATA cells but not from
    # quoted HEADER cells (@emlStripHeaderQuotes, eml-extract.praat: a
    # header written by R's write.csv(), which quotes headers by default,
    # arrives as the literal string "Q1" including the quote characters,
    # and "Get column index: "Q1"" then returns 0 against it). All three
    # declaration tables are exactly as hand-editable and
    # R/Excel-exportable as each other -- evidence/csv/
    # lane_survey_declared_SCHEMA.md says as much of the two declaration
    # files ("You can also edit them by hand") -- so all three are
    # normalized here, once, before the first "Get value" / "Get column
    # index" below. Every column-name lookup that follows -- "item",
    # "role", "reversed", "scale", "min", "max", and every user-declared
    # item name matched against the data table -- then sees clean labels,
    # rather than adding a quote check at each of the several sites that
    # look a column up. @emlStripHeaderQuotes is idempotent on a table
    # with no quoted labels, so this costs nothing on a clean file.
    #
    # Classifier-consumption sweep: @emlStripHeaderQuotes returns
    # .nStripped and .report$ (which headers it de-quoted); neither is
    # read at these three call sites, deliberately -- a de-quoted header
    # is a normalization, not a fault, and none of the fourteen refusals
    # below is "your header was quoted". Nothing here decides usability
    # the way @emlAuditColumn's kinds do, so there is no verdict to
    # partially consume.
    @emlStripHeaderQuotes: .itemsTableId
    @emlStripHeaderQuotes: .scalesTableId
    @emlStripHeaderQuotes: .dataTableId

    # --- .nScales and a safe default for EVERY per-scale array output,   ---
    # --- before ANYTHING else can exit this procedure early (V1.6, Fix 1) --
    # "Get number of rows" needs no particular column to exist, so this is
    # safe even when refusal 11 (immediately below) is about to find one
    # missing. It runs before refusal 11 for a narrower reason than
    # ordering: every one of .scaleName$[], .scaleType$[], .scaleMin[],
    # .scaleMax[] and .scaleIsKR20[] is a Praat INDEXED variable, and
    # reading an indexed variable that was never assigned ANY value HALTS
    # Praat with "Undefined indexed variable" -- a harder failure than the
    # plain `undefined` a caller gets from an ordinary never-assigned
    # scalar. Before V1.6, only .scaleIsKR20[] was seeded this way; the
    # other four are assigned solely in the scales-population loop below,
    # which sits AFTER refusal 11's exit -- so a caller that read any of
    # THOSE four after a refusal-11 return (exactly what this procedure's
    # own "Access pattern" section shows doing for .scaleIsKR20[], and
    # what validate/v129_survey_declaration.R's exhaustive output-contract
    # sweep now does for every documented output, on every refusal path)
    # crashed outright, because refusal 11 is the one refusal that can
    # fire before the scales-array population loop ever runs. Every
    # element of all five arrays is seeded here -- "" for the two string
    # arrays, `undefined` for the three numeric ones -- and overwritten
    # with its real value in that population loop when it runs; a scale
    # that refusal 11 refuses before reaching keeps its seeded default,
    # which is a value a caller can read, not a halt. THE RULE THIS
    # GENERALIZES, stated once in the Outputs header below: every
    # documented output holds a defined value on every return.
    selectObject: .scalesTableId
    .nScales = Get number of rows
    for .s from 1 to .nScales
        .scaleName$[.s] = ""
        .scaleType$[.s] = ""
        .scaleMin[.s] = undefined
        .scaleMax[.s] = undefined
        .scaleIsKR20[.s] = undefined
    endfor

    # ===== Refusal 11: a required column is missing from either =====
    # ===== declaration file                                     =====
    # Checked before ANYTHING else in this procedure touches either table.
    # The two array-population loops immediately below read every one of
    # these seven columns with a bare "Get value:", which HALTS Praat
    # outright when the named column does not exist -- proved live on a
    # three-column "scale,min,max" scales file (the shape every
    # declaration written before V1.2 has): "Error: Table ""scales_notype"":
    # there is no column named ""type""". @emlRequireColumnPresent
    # (eml-inferential.praat) turns that halt into an ordinary .error$
    # instead, so every column either loop is about to read is confirmed
    # present here first, in the same order each loop reads it in: the
    # items table's "item", "role", "reversed", then the scales table's
    # "scale", "min", "max", "type". This is the ONE canon list of
    # required columns for this procedure; nothing below restates it.
    .reqColCount = 7
    .reqColTable[1] = .itemsTableId
    .reqColFile$[1] = "survey_items.csv"
    .reqColName$[1] = "item"
    .reqColTable[2] = .itemsTableId
    .reqColFile$[2] = "survey_items.csv"
    .reqColName$[2] = "role"
    .reqColTable[3] = .itemsTableId
    .reqColFile$[3] = "survey_items.csv"
    .reqColName$[3] = "reversed"
    .reqColTable[4] = .scalesTableId
    .reqColFile$[4] = "survey_scales.csv"
    .reqColName$[4] = "scale"
    .reqColTable[5] = .scalesTableId
    .reqColFile$[5] = "survey_scales.csv"
    .reqColName$[5] = "min"
    .reqColTable[6] = .scalesTableId
    .reqColFile$[6] = "survey_scales.csv"
    .reqColName$[6] = "max"
    .reqColTable[7] = .scalesTableId
    .reqColFile$[7] = "survey_scales.csv"
    .reqColName$[7] = "type"

    for .c from 1 to .reqColCount
        @emlRequireColumnPresent: .reqColTable[.c], "Declaration column",
        ... .reqColName$[.c]
        if emlRequireColumnPresent.error$ <> ""
            .error$ = .msg11a$ + .reqColFile$[.c] + .msg11b$
            ... + .reqColName$[.c] + .msg11c$
            .remedy$ = .rem11a$ + .reqColName$[.c] + .rem11b$
            ... + .reqColFile$[.c] + .rem11c$
            .refusal = 11
            .badColumn$ = .reqColName$[.c]
            .badFile$ = .reqColFile$[.c]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # --- Read the items table into procedure-local arrays ---
    selectObject: .itemsTableId
    .nItems = Get number of rows
    for .i from 1 to .nItems
        selectObject: .itemsTableId
        .itemName$[.i] = Get value: .i, "item"
        .itemRole$[.i] = Get value: .i, "role"
        .itemReversed[.i] = Get value: .i, "reversed"
        ; V1.3: the RAW string alongside the numeric parse, for refusal
        ; 6's message. ".itemReversed[.i]" above is `undefined` for a
        ; non-numeric cell (e.g. "yes"), and printing that with
        ; "string$ (...)" produces the internal token "--undefined--" in a
        ; user-facing message -- the exact class of fault this pass is
        ; closing on the scales file, found here on the items file too.
        ; The raw text is read once, here, rather than re-read at the
        ; refusal 6 message site below.
        .itemReversedRaw$[.i] = Get value: .i, "reversed"
    endfor

    # --- Read the scales table into procedure-local arrays ---
    selectObject: .scalesTableId
    .nScales = Get number of rows
    for .s from 1 to .nScales
        selectObject: .scalesTableId
        .scaleName$[.s] = Get value: .s, "scale"
        .scaleMin[.s] = Get value: .s, "min"
        .scaleMax[.s] = Get value: .s, "max"
        ; V1.2: read once, into the same loop, rather than a second pass --
        ; refusal 9 needs .scaleType$[] and refusal 10 needs .scaleMin[] /
        ; .scaleMax[], already read above.
        .scaleType$[.s] = Get value: .s, "type"
        ; V1.2: the KR-20 naming condition, stated ONCE, here, as soon as
        ; min and max are both in hand -- "the declared range spans exactly
        ; two values, max = min + 1" (established ruling: this is a naming
        ; condition on the DECLARED RANGE alone, independent of the
        ; declared type, and it is not restated anywhere else in this
        ; procedure). Exposed as an output so Stage 2 does not re-derive it
        ; from scratch. Meaningful only when this procedure returns
        ; .refusal = 0 for a given scale; a scale that fails refusal 9 or
        ; 10 still gets an entry here, computed from whatever min/max it
        ; declared, but that entry is moot once the declaration itself is
        ; refused.
        .scaleIsKR20[.s] = .scaleMax[.s] = .scaleMin[.s] + 1
    endfor

    # ===== Refusal 14: a scale name is empty =====
    # Checked before refusal 13 (duplicate scale name): whether a scale
    # HAS a name at all is the more basic fact about it. Unchecked before
    # V1.3 by the same gap named in this pass's header: an empty scale
    # name is never matched against a data column the way an item name is
    # (refusal 1), so nothing else in this procedure would ever catch it.
    #
    # Finding 6: `.scaleName$[.s] = ""` tested EXACT empty, not trimmed --
    # a scales file whose scale name is a single space validated clean and
    # declared a live subscale with a whitespace name. Two existing
    # trimming classifiers could close this: @eml_normalizeLabel
    # (eml-extract.praat) trims and lower-cases for label COMPARISON, and
    # @eml_classifyCell (eml-extract.praat, the same classifier refusals 8
    # and 12 already use above) folds a whitespace-only string AND
    # Praat's own missing-value token "--undefined--" into one kind (kind
    # 1, "empty"). @eml_classifyCell is used here, not
    # @eml_normalizeLabel: a scale name is not being compared against
    # another label (lower-casing would be pointless work), and a scale
    # name column round-tripped through Praat can contain the literal
    # "--undefined--" token exactly as Finding 2 proved a min/max column
    # can -- @eml_normalizeLabel's plain trim would not catch that
    # spelling of "no name" at all, where @eml_classifyCell's kind 1
    # already does.
    for .s from 1 to .nScales
        @eml_classifyCell: .scaleName$[.s]
        .scaleNameKind = eml_classifyCell.kind
        if .scaleNameKind = 1
            .error$ = .msg14a$ + string$ (.s) + .msg14b$
            .remedy$ = .rem14a$
            .refusal = 14
            .badScaleRow = .s
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 13: a scale name declared more than once =====
    # Shares its scan with refusal 7 (an item name declared more than
    # once, below) via @eml_findDuplicateName: the two ask the same
    # question of two different tables/columns, and V1.3 does not want a
    # second copy of that nested loop.
    #
    # Classifier-consumption sweep: @eml_findDuplicateName returns four
    # outputs (.found, .name$, .firstRow, .dupRow). .firstRow is the ONE
    # output deliberately not read here or at refusal 7's call site below
    # -- the message names only .dupRow, the LATER declaration, because
    # the first occurrence is not itself wrong (nothing to fix there) and
    # naming the second names the row to delete. This is not a missed
    # kind the way refusal 8's four discarded kinds were: .found/.name$/
    # .dupRow already fully decide the refusal and fully name the fix.
    @eml_findDuplicateName: .scalesTableId, "scale", .nScales, 0
    if eml_findDuplicateName.found = 1
        .error$ = .msg13a$ + eml_findDuplicateName.name$ + .msg13b$
        ... + string$ (eml_findDuplicateName.dupRow) + .msg13c$
        .remedy$ = .rem13a$ + eml_findDuplicateName.name$ + .rem13b$
        .refusal = 13
        .badScale$ = eml_findDuplicateName.name$
        .badScaleRow = eml_findDuplicateName.dupRow
        goto SURVEY_VALIDATE_DONE
    endif

    # ===== Refusal 17: two scale names collide once underscore-normalized =====
    # [Stage 3 ruling, item 5.] Checked immediately after refusal 13: by the
    # time this runs, every RAW scale name is already known unique (refusal
    # 13 above would already have refused a raw duplicate), so any
    # collision @eml_findDuplicateName reports here, with .normalize = 1,
    # is necessarily between two DIFFERENT raw spellings that only
    # coincide once spaces become underscores -- exactly "Vocal Health"
    # and "Vocal_Health" colliding in the scores table and in any file
    # stem (item 4's contract). Reuses the SAME shared scan refusal
    # 7/13/15 already use, not a second nested loop.
    @eml_findDuplicateName: .scalesTableId, "scale", .nScales, 1
    if eml_findDuplicateName.found = 1
        @eml_underscoreNormalize: eml_findDuplicateName.rawName1$
        .collidedName$ = eml_underscoreNormalize.result$
        .error$ = .msg17a$ + eml_findDuplicateName.rawName1$ + .msg17b$
        ... + string$ (eml_findDuplicateName.firstRow) + .msg17c$
        ... + eml_findDuplicateName.rawName2$ + .msg17d$
        ... + string$ (eml_findDuplicateName.dupRow) + .msg17e$
        ... + .collidedName$ + .msg17f$
        .remedy$ = .rem17a$ + eml_findDuplicateName.rawName1$ + .rem17b$
        ... + eml_findDuplicateName.rawName2$ + .rem17c$
        .refusal = 17
        .badScale$ = eml_findDuplicateName.rawName2$
        .badScaleRow = eml_findDuplicateName.dupRow
        goto SURVEY_VALIDATE_DONE
    endif

    # ===== Refusal 12: a subscale's declared min or max is missing or =====
    # ===== not numeric                                                =====
    # @emlRequireNumericColumn (eml-inferential.praat), strict = 1, decides
    # WHETHER the "min" (then "max") column is clean: strict mode refuses
    # when ANY cell is unusable, which covers both a non-numeric endpoint
    # and a missing one (an empty cell is not "kind 0 valid" either).
    # Before this, "Get value:" silently returned `undefined` for either
    # fault and every guard downstream that compared against it -- refusal
    # 10's ">=" and refusal 2's range check -- was FALSE against
    # `undefined` on either side, so both silently disabled (proved live:
    # "Confidence,one,5,ordinal" returned refusal = 0). Checked before
    # refusal 10, which depends on both endpoints already being usable
    # numbers.
    #
    # @emlRequireNumericColumn does not itself say WHICH row is bad, so
    # once it says a column is not clean, the specific row is located with
    # @emlAuditColumn -- the same per-cell classifier refusal 8 already
    # calls directly, above, rather than a second classifier -- by taking
    # the smallest of its five "first bad row" outputs that is nonzero
    # (whichever condition the bad cell falls under: empty, comma-locale,
    # coerced, leading-dot, or outright unreadable, the row with the
    # smallest number is the first one that made the column unusable). Its
    # RAW text is then read as a STRING, not re-derived or re-classified,
    # purely to name it in the message without ever printing
    # "--undefined--" (refusal 5, this pass's own header finding).
    # ----- V1.6, Fix 2: a whitespace-only endpoint, checked BEFORE either -
    # ----- column is ever handed to @emlRequireNumericColumn             -
    # @eml_strictNumericColumn (eml-extract.praat)'s own pre-scan recognises
    # only "", "--undefined--" and "?" as unreadable before its fast path
    # calls Praat's own "Get all numbers in column:" -- a cell holding only
    # whitespace (e.g. a single space) matches none of the three, so the
    # fast path proceeds and PRAAT ITSELF HALTS: "the cell in row R of
    # column [min|max] is undefined ... cannot get all numbers in column
    # [N]", proved live on "Confidence, ,5,ordinal". eml-extract.praat is
    # outside this lane's boundary, so calling @emlRequireNumericColumn (or
    # @emlAuditColumn) on a column already carrying this landmine cell is
    # avoided altogether, rather than caught after the fact -- by that
    # point the halt has already happened. @eml_findWhitespaceOnlyCell
    # (above) answers the question with @eml_classifyCell, the classifier
    # this procedure already calls for exactly this kind of question, not a
    # second, narrower reimplementation of "unreadable". A whitespace-only
    # endpoint is exactly refusal 12's own "empty" branch below -- the same
    # message, and the same .badRawValue$ = "" this procedure now uses for
    # every empty-endpoint spelling (Fix 1, header defect b) -- so it is
    # built inline here rather than falling through to the shared branch
    # that only runs once a column has actually been read successfully.
    @eml_findWhitespaceOnlyCell: .scalesTableId, "min", .nScales
    if eml_findWhitespaceOnlyCell.found = 1
        .badScaleRow = eml_findWhitespaceOnlyCell.row
        .badScale$ = .scaleName$[.badScaleRow]
        .badColumn$ = "min"
        .badRawValue$ = ""
        .error$ = .msg12a$ + .badScale$ + .msg12b$ + .badColumn$ + .msg12eEmpty$
        .remedy$ = .rem12a$ + .badColumn$ + .rem12b$ + .badScale$ + .rem12c$
        .refusal = 12
        goto SURVEY_VALIDATE_DONE
    endif

    @emlRequireNumericColumn: .scalesTableId, "Subscale range", "min", 1
    .badEndpointError$ = emlRequireNumericColumn.error$
    .badEndpointCol$ = "min"
    if .badEndpointError$ = ""
        @eml_findWhitespaceOnlyCell: .scalesTableId, "max", .nScales
        if eml_findWhitespaceOnlyCell.found = 1
            .badScaleRow = eml_findWhitespaceOnlyCell.row
            .badScale$ = .scaleName$[.badScaleRow]
            .badColumn$ = "max"
            .badRawValue$ = ""
            .error$ = .msg12a$ + .badScale$ + .msg12b$ + .badColumn$ + .msg12eEmpty$
            .remedy$ = .rem12a$ + .badColumn$ + .rem12b$ + .badScale$ + .rem12c$
            .refusal = 12
            goto SURVEY_VALIDATE_DONE
        endif
        @emlRequireNumericColumn: .scalesTableId, "Subscale range", "max", 1
        .badEndpointError$ = emlRequireNumericColumn.error$
        .badEndpointCol$ = "max"
    endif
    if .badEndpointError$ <> ""
        @emlAuditColumn: .scalesTableId, .badEndpointCol$
        # Finding 7: this call's .error$ was consumed at refusal 8's own
        # @emlAuditColumn call site, ~170 lines below, but not here --
        # this pass's rule admits no exception for a call site just
        # because its error is not reachable today. "min" and "max" are
        # both guaranteed present by refusal 11, checked earlier in this
        # same procedure, so .error$ (column not found) cannot actually
        # be non-empty here -- but if it ever were, indexing
        # .scaleName$[.badScaleRow] below at row 0 (nothing sets
        # .badScaleRow when every "first...Row" output stays at its
        # initialized 0) HALTS with "Undefined indexed variable" rather
        # than refusing. Guarded, not left to chance.
        if emlAuditColumn.error$ <> ""
            .error$ = .msg12fCol$ + .badEndpointCol$ + .msg12gCol$
            .remedy$ = .rem12dCol$ + .badEndpointCol$ + .rem12eCol$
            .refusal = 12
            goto SURVEY_VALIDATE_DONE
        endif
        .badScaleRow = 0
        if emlAuditColumn.firstEmptyRow > 0
            .badScaleRow = emlAuditColumn.firstEmptyRow
        endif
        if emlAuditColumn.firstLocaleRow > 0
            if .badScaleRow = 0 or emlAuditColumn.firstLocaleRow < .badScaleRow
                .badScaleRow = emlAuditColumn.firstLocaleRow
            endif
        endif
        if emlAuditColumn.firstCoercedRow > 0
            if .badScaleRow = 0 or emlAuditColumn.firstCoercedRow < .badScaleRow
                .badScaleRow = emlAuditColumn.firstCoercedRow
            endif
        endif
        if emlAuditColumn.firstLeadingDotRow > 0
            if .badScaleRow = 0 or emlAuditColumn.firstLeadingDotRow < .badScaleRow
                .badScaleRow = emlAuditColumn.firstLeadingDotRow
            endif
        endif
        if emlAuditColumn.firstUnreadableRow > 0
            if .badScaleRow = 0 or emlAuditColumn.firstUnreadableRow < .badScaleRow
                .badScaleRow = emlAuditColumn.firstUnreadableRow
            endif
        endif
        .badScale$ = .scaleName$[.badScaleRow]
        .badColumn$ = .badEndpointCol$
        selectObject: .scalesTableId
        .badRawValue$ = Get value: .badScaleRow, .badEndpointCol$
        # Finding 2: THE MESSAGE CLASS, closed, not just this one branch.
        # Praat's own missing-value token in a saved CSV is the literal
        # 13-character string "--undefined--", never the empty string
        # (CLAUDE.md / this pass's header) -- so
        # "Confidence,--undefined--,5,ordinal", the exact shape a
        # round-tripped declaration can contain (the schema doc: "the
        # dialog writes both declaration files"), used to fail the old
        # `.badRawValue$ = ""` test and print the bare internal token to
        # the user in the "else" branch below. @eml_classifyCell
        # (eml-extract.praat) is the one place that already folds BOTH
        # spellings of "nothing here" into its kind 1 ("empty"), so that
        # classifier decides the branch here instead of a second, narrower
        # re-implementation of the same test that only one of the two
        # spellings would pass.
        @eml_classifyCell: .badRawValue$
        if eml_classifyCell.kind = 1
            # V1.6 (Fix 1, header defect b): THE VALUE now matches the
            # Outputs header's own claim -- "" both when the cell is
            # itself empty and when refusal is not 12 -- rather than the
            # header being loosened to admit "--undefined--" too. Before
            # this, a caller reading .badRawValue$ DIRECTLY (not just
            # .error$'s sentence, which already took this branch) still
            # saw the literal round-tripped token on this exact fixture.
            # Forcing it here, once, is the same fix as the message
            # class this branch already closes, applied to the OUTPUT
            # rather than only the sentence built from it.
            .badRawValue$ = ""
            .error$ = .msg12a$ + .badScale$ + .msg12b$ + .badColumn$
            ... + .msg12eEmpty$
        else
            .error$ = .msg12a$ + .badScale$ + .msg12b$ + .badColumn$
            ... + .msg12cText$ + .badRawValue$ + .msg12dText$
        endif
        .remedy$ = .rem12a$ + .badColumn$ + .rem12b$ + .badScale$
        ... + .rem12c$
        .refusal = 12
        goto SURVEY_VALIDATE_DONE
    endif

    selectObject: .dataTableId
    .nData = Get number of rows

    # ===== Refusal 15 [V1.5]: two data-table columns share the same =====
    # ===== header label                                             =====
    # Checked before refusal 1: a duplicated header makes refusal 1's own
    # "Get column index:" lookup unreliable (it resolves to the FIRST
    # match and reports success either way), so this must be settled
    # before refusal 1's answer can be trusted at all. Proved live
    # (Finding 4a): a data table with two "Q1" columns, the second holding
    # 99 in row 3 and "abc" in row 4, with "Q1" declared once in
    # survey_items.csv, returned refusal 0 -- the out-of-range 99 (refusal
    # 2's question) and the unreadable "abc" (refusal 8's question) both
    # escape, because every read of "Q1" below, by name, addresses only
    # the first column.
    #
    # Reused, not rewritten: @eml_findDuplicateName (above) already
    # answers "does a name repeat" for a table's named COLUMN OF VALUES.
    # A data table's own column LABELS are metadata, not a column of
    # values, so they cannot be handed to it directly -- a scratch
    # one-column Table holding the data table's labels, one per row (built
    # fresh, then removed), lets the SAME helper answer the identical
    # question about headers instead of a second nested duplicate scan
    # written out here.
    selectObject: .dataTableId
    .nDataCols = Get number of columns
    .dataColLabelsTable = Create Table with column names: "eml_dataColLabels",
        ... 0, "label"
    for .c from 1 to .nDataCols
        selectObject: .dataTableId
        .dataColLabel$ = Get column label: .c
        selectObject: .dataColLabelsTable
        Append row
        Set string value: .c, "label", .dataColLabel$
    endfor
    @eml_findDuplicateName: .dataColLabelsTable, "label", .nDataCols, 0
    removeObject: .dataColLabelsTable
    ; .dupDataColFound holds the classifier's own verdict in a name unique
    ; to this call site, kept apart from refusal 7's and 13's identically
    ; worded "if eml_findDuplicateName.found = 1" guards elsewhere in this
    ; procedure so a negative control aimed at any one of the three has a
    ; guard line to target that is not shared text.
    .dupDataColFound = eml_findDuplicateName.found
    if .dupDataColFound = 1
        .error$ = .msg15a$ + eml_findDuplicateName.name$ + .msg15b$
        .remedy$ = .rem15a$ + eml_findDuplicateName.name$ + .rem15b$
        .refusal = 15
        .badItem$ = eml_findDuplicateName.name$
        goto SURVEY_VALIDATE_DONE
    endif

    # --- V1.2: each item's resolved subscale, computed ONCE -------------
    # An item's role resolves to a declared subscale when it names a value
    # in .scaleName$[]; "grouping", "ignore", and any role naming no
    # declared scale (refusal 5's own question) resolve to 0. Refusal 2's
    # own inline loop below asks this same question a second time, by
    # design: refusal 2 is pre-existing V1.1 code and this addition does
    # not alter it. Refusal 8, added in V1.2, reads .itemScaleIndex[] here
    # instead of writing that loop a third time.
    for .i from 1 to .nItems
        .itemScaleIndex[.i] = 0
        for .s from 1 to .nScales
            if .itemRole$[.i] = .scaleName$[.s]
                .itemScaleIndex[.i] = .s
            endif
        endfor
    endfor

    # ===== Refusal 1: item names a column the data table lacks =====
    for .i from 1 to .nItems
        selectObject: .dataTableId
        .colIndex = Get column index: .itemName$[.i]
        if .colIndex = 0
            .error$ = .msg1a$ + .itemName$[.i] + .msg1b$
            .remedy$ = .rem1$
            .refusal = 1
            .badItem$ = .itemName$[.i]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 16 [V1.5]: a data-table column is not declared by =====
    # ===== any item                                                  =====
    # Refusal 1, immediately above, establishes the ITEMS -> DATA
    # direction: every row in survey_items.csv must name a column the
    # data table has. This is that same discipline in the opposite
    # direction, the same way refusal 5 already holds the scales file and
    # the items file to a two-way standard rather than just one. The
    # schema (evidence/csv/lane_survey_declared_SCHEMA.md) says the items
    # file lists every column of the data table, one row per column; a
    # column present in the data and absent from survey_items.csv was
    # silently neither scored (no item claims it) nor disclosed as
    # deliberately skipped -- "ignore" is itself a role an item ROW
    # declares, so a column with no item row was never actually told
    # apart from one nobody remembered to declare at all.
    #
    # .nDataCols is already known from refusal 15's scan, above, and the
    # data table's columns have not changed since -- recomputing it here
    # would be exactly the drift this pass's own DRY rule warns against.
    for .c from 1 to .nDataCols
        selectObject: .dataTableId
        .dataColLabel$ = Get column label: .c
        .dataColDeclared = 0
        for .i from 1 to .nItems
            if .itemName$[.i] = .dataColLabel$
                .dataColDeclared = 1
            endif
        endfor
        if .dataColDeclared = 0
            .error$ = .msg16a$ + .dataColLabel$ + .msg16b$
            .remedy$ = .rem16a$ + .dataColLabel$ + .rem16b$
            .refusal = 16
            .badItem$ = .dataColLabel$
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== V1.2 additions: refusals 7, 6, 9, 10, 8 =====
    # All five are inserted HERE -- after refusal 1, before refusal 2 --
    # per the ordering rationale in this procedure's header comment: 7, 6,
    # 9 and 10 are pure declaration-shape faults (decided from
    # survey_items.csv / survey_scales.csv alone) and must run before any
    # refusal that reads respondent data; 8 reads respondent data but must
    # still run before refusal 2 reaches the same cells (refusal 8's own
    # reason for existing). None of the five touches refusal 1's own logic
    # above or refusal 2's below.

    # ===== Refusal 7: an item name declared more than once =====
    # A later duplicate is reported by ITS OWN row number in
    # survey_items.csv: the first occurrence is not itself wrong, so
    # naming the second occurrence names the row to delete. V1.3:
    # refactored onto @eml_findDuplicateName, shared with refusal 13's
    # identical question about survey_scales.csv's "scale" column --
    # behavior unchanged, same message fragments, same outputs. .firstRow
    # is deliberately not read here either -- same reason as refusal 13's
    # call site, above.
    @eml_findDuplicateName: .itemsTableId, "item", .nItems, 0
    if eml_findDuplicateName.found = 1
        .error$ = .msg7a$ + eml_findDuplicateName.name$ + .msg7b$
        ... + string$ (eml_findDuplicateName.dupRow) + .msg7c$
        .remedy$ = .rem7a$ + eml_findDuplicateName.name$ + .rem7b$
        .refusal = 7
        .badItem$ = eml_findDuplicateName.name$
        .badItemRow = eml_findDuplicateName.dupRow
        goto SURVEY_VALIDATE_DONE
    endif

    # ===== Refusal 6: reversed holds a value other than 0 or 1 =====
    for .i from 1 to .nItems
        if .itemReversed[.i] <> .reversedValueFalse and .itemReversed[.i] <> .reversedValueTrue
            ; V1.3: the message names the RAW declared value
            ; (.itemReversedRaw$[.i]), not "string$ (.itemReversed[.i])".
            ; A non-numeric "reversed" cell (e.g. "yes") makes the numeric
            ; parse `undefined`, and printing that with "string$ (...)"
            ; produced the internal token "--undefined--" in a user-facing
            ; message here -- the same class of fault this pass closes on
            ; the scales file (refusal 12), found on this message too.
            .error$ = .msg6a$ + .itemName$[.i] + .msg6b$
            ... + .itemReversedRaw$[.i] + .msg6c$
            .remedy$ = .rem6a$ + .itemName$[.i] + .rem6b$
            .refusal = 6
            .badItem$ = .itemName$[.i]
            .badItemRow = .i
            .badReversedValue = .itemReversed[.i]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 9: a scale type that is neither ordinal nor continuous =====
    for .s from 1 to .nScales
        if .scaleType$[.s] <> .typeKeywordOrdinal$ and .scaleType$[.s] <> .typeKeywordContinuous$
            .error$ = .msg9a$ + .scaleName$[.s] + .msg9b$ + .scaleType$[.s]
            ... + .msg9c$
            .remedy$ = .rem9a$ + .scaleName$[.s] + .rem9b$
            .refusal = 9
            .badScale$ = .scaleName$[.s]
            .badScaleRow = .s
            .badTypeValue$ = .scaleType$[.s]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 10 [CONTRACT REPAIR -- Ian's to veto]: a declared =====
    # ===== minimum not below its declared maximum                  =====
    # Checked BEFORE refusal 2 so a transposed pair of endpoints is caught
    # as the declaration fault it is, rather than reaching refusal 2's
    # per-respondent range check and being reported as a bad DATA row.
    for .s from 1 to .nScales
        if .scaleMin[.s] >= .scaleMax[.s]
            .error$ = .msg10a$ + .scaleName$[.s] + .msg10b$
            ... + string$ (.scaleMin[.s]) + .msg10c$ + string$ (.scaleMax[.s])
            ... + .msg10d$
            .remedy$ = .rem10a$ + .scaleName$[.s] + .rem10b$
            .refusal = 10
            .badScale$ = .scaleName$[.s]
            .badScaleRow = .s
            .badMin = .scaleMin[.s]
            .badMax = .scaleMax[.s]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== V1.7, cell ruling, branches 1 and 2: missing-value placeholder =====
    # ===== disclosure -- a FULL pass, run before refusal 8's own cascade =====
    # Superseding refusal 8's old behaviour: before this pass existed,
    # refusal 8 (below) refused on EVERY cell it could not read as a
    # number, with no further question asked. Under the cell ruling, a
    # cell @emlRepairClassify (eml-extract.praat:2665) recognises as one of
    # its own kind-3 missing-value spellings is no longer refused -- it is
    # treated as ordinary missingness, exactly like a blank cell, and its
    # presence is disclosed rather than silently reinterpreted. Any OTHER
    # cell refusal 8 could not read still refuses there, unchanged.
    #
    # This pass never exits early with a `goto`: it runs over EVERY
    # subscale item's column in full, so a placeholder found in one
    # item's column is disclosed even when a LATER item's column is what
    # actually makes this declaration refuse (a whitespace-only cell kept
    # under refusal 8's own Fix 3 pre-check, below, or any later refusal).
    # "The disclosure is ALWAYS PRINTED when any placeholder was found" (the
    # cell ruling) means unconditionally on that fact alone, not
    # conditionally on the run's eventual verdict -- v129's [cell ruling,
    # mixed] leg seeds exactly this: a recognised placeholder in one
    # item's column and a whitespace-only cell in another's, and asserts
    # the disclosure still fires despite the whitespace refusal that
    # follows it.
    #
    # @eml_scanColumnForPlaceholders (above) does the per-cell work, once
    # per item; its .firstGenuineBadRow$ / .firstGenuineBadText$ are
    # cached here, into .itemFirstGenuineBadRow[.i] /
    # .itemFirstGenuineBadText$[.i], so refusal 8's own cascade, below,
    # reuses them instead of scanning the same column a second time.
    # (.disclosureCount / .disclosureSpellingCount / .disclosureItemCount
    # are already 0 from the seeding block at procedure entry; not
    # re-zeroed here, so this pass only ever adds to them.)
    for .i from 1 to .nItems
        .itemFirstGenuineBadRow[.i] = 0
        .itemFirstGenuineBadText$[.i] = ""
        if .itemScaleIndex[.i] > 0
            @eml_scanColumnForPlaceholders: .dataTableId, .itemName$[.i], .nData
            .itemFirstGenuineBadRow[.i] = eml_scanColumnForPlaceholders.firstGenuineBadRow
            .itemFirstGenuineBadText$[.i] = eml_scanColumnForPlaceholders.firstGenuineBadText$
            if eml_scanColumnForPlaceholders.nPlaceholder > 0
                .itemHasPlaceholder = 0
                for .p from 1 to eml_scanColumnForPlaceholders.nPlaceholder
                    .disclosureCount = .disclosureCount + 1
                    .pText$ = eml_scanColumnForPlaceholders.placeholderText$[.p]
                    .seenSpelling = 0
                    for .q from 1 to .disclosureSpellingCount
                        if .disclosureSpelling$[.q] = .pText$
                            .seenSpelling = 1
                        endif
                    endfor
                    if .seenSpelling = 0
                        .disclosureSpellingCount = .disclosureSpellingCount + 1
                        .disclosureSpelling$[.disclosureSpellingCount] = .pText$
                    endif
                    .itemHasPlaceholder = 1
                endfor
                if .itemHasPlaceholder = 1
                    .disclosureItemCount = .disclosureItemCount + 1
                    .disclosureItem$[.disclosureItemCount] = .itemName$[.i]
                endif
            endif
        endif
    endfor

    # THE DISCLOSURE ITSELF, ASSEMBLED FROM THE THREE FACTS THE CELL RULING
    # NAMES -- how many cells, which spellings, which items -- and PRINTED
    # (appendInfoLine) UNCONDITIONALLY whenever .disclosureCount > 0, never
    # gated behind .refusal staying 0: see the header comment above this
    # pass for why. .disclosure$ is also returned as an output, "" exactly
    # when .disclosureCount is 0, the same empty-exactly-when-nothing-to-
    # say contract this procedure's .error$/.remedy$ already keep.
    .disclosure$ = ""
    if .disclosureCount > 0
        .spellList$ = ""
        for .q from 1 to .disclosureSpellingCount
            if .q > 1
                .spellList$ = .spellList$ + ", "
            endif
            .spellList$ = .spellList$ + """" + .disclosureSpelling$[.q] + """"
        endfor
        .itemList$ = ""
        for .q from 1 to .disclosureItemCount
            if .q > 1
                .itemList$ = .itemList$ + ", "
            endif
            .itemList$ = .itemList$ + .disclosureItem$[.q]
        endfor
        .disclosure$ = string$ (.disclosureCount) + .msgDiscA$ + .spellList$
        ... + .msgDiscB$ + .itemList$ + .msgDiscC$
        appendInfoLine: .disclosure$
    endif

    # ===== Refusal 8: an item resolved to a subscale has an unusable =====
    # ===== data column                                              =====
    # Only items whose role resolves to a declared subscale need numeric
    # data (.itemScaleIndex[.i] > 0, computed once above) -- a grouping or
    # ignore column may legitimately hold text, e.g. Voice holding
    # "Soprano" / "Alto", and is not checked here. @emlAuditColumn
    # (eml-extract.praat) classifies every cell of a column into five
    # kinds: 1 empty, 2 locale-comma, 3 unreadable, 4 coerced, 5
    # leading-dot. V1.2 (this refusal's own introduction) read only kind
    # 3. A verification pass (Finding 1) proved that left kinds 2, 4 and 5
    # live: on the committed fixture, R1 row 2 "71.8" edited to "71,8"
    # (kind 2) is silently misread by "Get value:" as 71 -- not dropped,
    # not flagged, a DIFFERENT number -- moving Ease's alpha from
    # 0.941046 to 0.940856 while this refusal still reported 0; the same
    # cell edited to ".5" (kind 5) reads `undefined` and is silently
    # dropped by listwise deletion, again with refusal still 0. Both are
    # now joined below alongside kind 3 and kind 4 (a percent sign coerces
    # the same way), so every kind @emlAuditColumn calls unusable-but-not-
    # missing refuses here.
    #
    # Kind 1 (genuinely empty) is the one kind deliberately EXCLUDED from
    # this refusal, not merely overlooked: an empty respondent cell is
    # ordinary missingness, already disclosed and handled by listwise
    # deletion, and is not evidence that the column itself is the wrong
    # one -- the fault this refusal exists to catch (this procedure's own
    # header comment for refusal 8, above, and refusal 2's header comment
    # on the same exemption). A real missing cell stays exempt exactly as
    # before.
    for .i from 1 to .nItems
        if .itemScaleIndex[.i] > 0
            # ----- V1.6, Fix 3: a whitespace-only DATA cell, checked -----
            # ----- BEFORE this column is ever handed to @emlAuditColumn --
            # @emlAuditColumn's own fast path (eml-extract.praat:
            # @eml_strictNumericColumn) is exactly the call Fix 2 above
            # already keeps away from a "min"/"max" column carrying this
            # landmine, for the identical reason: its pre-scan does not
            # recognise a whitespace-only cell as unreadable, so nothing
            # stops it reaching Praat's own "Get all numbers in column:",
            # which halts outright rather than returning control to this
            # module. Verified live on a DATA column: a single space in
            # item column "R1", respondent row 2, aborts with "Table
            # ""eml_numericProbe"": the cell in row 2 of column ""R1"" is
            # undefined" before this refusal, or refusal 2 below it, ever
            # gets a chance to run. @eml_findWhitespaceOnlyCell (above) is
            # reused unchanged, not reimplemented a second time for data
            # columns.
            #
            # DECISION: refused here, as an unusable value (this refusal's
            # own "kind 3, unreadable" wording, msg8a..msg8e, reused
            # verbatim below), not folded into kind 1's ordinary
            # missingness. The two are NOT the same fact for a DATA
            # column, even though @eml_classifyCell files both under its
            # own kind 1: a genuinely empty cell is safe wherever it is
            # read again, because @eml_strictNumericColumn's pre-scan
            # recognises "" and "--undefined--" by name and diverts them
            # to a per-cell path before its crash-prone fast path ever
            # runs. A whitespace-only cell is exactly what that pre-scan
            # fails to recognise -- the gap this fix closes -- so it is
            # NOT safe downstream: any later read of this same column for
            # real computation (eml-extract.praat, outside this lane) hits
            # the identical halt this refusal exists to prevent, not a
            # quietly-dropped row. Treating it as missing here would only
            # move today's crash to a later, unguarded line, defeating the
            # one promise this whole procedure makes -- checked before any
            # number is computed. Checked first, before @emlAuditColumn's
            # own four-kind scan below, for the same reason Fix 2 checks
            # "min" and "max" first: a column carrying this landmine
            # cannot be handed to @emlAuditColumn at all, so whether some
            # OTHER cell in the same column is bad, and at an earlier row,
            # cannot be learned without incurring the very crash being
            # avoided. Reporting the whitespace-only row itself is the one
            # answer available without it -- the same trade-off Fix 2
            # already accepts on the scales file.
            # V1.7, cell ruling: NOT reclassified as a placeholder here.
            # @emlRepairClassify, the ruling's stated authority for what
            # counts as a recognised missing-value spelling, trims a
            # whitespace-only cell to "" and returns its OWN kind 0
            # ("nothing to do"), never kind 3 -- so consuming its whole
            # verdict on this exact text leaves this branch exactly where
            # it already was, refusing, without this module inventing a
            # whitespace exception of its own. The filed classifier fix
            # that would fold whitespace into kind 3 lives in the other
            # lane and has not landed; once it does, this cell joins
            # branch 1 above with no further change needed here, because
            # this block asks @emlRepairClassify's real verdict rather
            # than restating a list.
            @eml_findWhitespaceOnlyCell: .dataTableId, .itemName$[.i], .nData
            if eml_findWhitespaceOnlyCell.found = 1
                .matchedScaleIdx = .itemScaleIndex[.i]
                .badAuditRow = eml_findWhitespaceOnlyCell.row
                selectObject: .dataTableId
                .badAuditText$ = Get value: .badAuditRow, .itemName$[.i]
                .error$ = .msg8a$ + .itemName$[.i] + .msg8b$
                ... + .scaleName$[.matchedScaleIdx] + .msg8c$
                ... + string$ (.badAuditRow) + .msg8d$
                ... + .badAuditText$ + .msg8e$
                .remedy$ = .rem8a$ + .itemName$[.i] + .rem8b$
                ... + string$ (.badAuditRow) + .rem8c$ + .rem8d$
                .refusal = 8
                .badItem$ = .itemName$[.i]
                .badScale$ = .scaleName$[.matchedScaleIdx]
                .badRow = .badAuditRow
                .badCellText$ = .badAuditText$
                goto SURVEY_VALIDATE_DONE
            endif

            @emlAuditColumn: .dataTableId, .itemName$[.i]
            if emlAuditColumn.error$ = ""
                # The smallest nonzero "first row" across the four
                # unusable-and-not-missing kinds, the same "earliest bad
                # row wins" rule refusal 12 already applies to the scales
                # file's min/max columns below -- so a column with more
                # than one bad kind still reports the row that broke it
                # first, not whichever kind happened to be tested last.
                .badAuditRow = 0
                .badAuditText$ = ""
                if emlAuditColumn.nLocale > 0
                    .badAuditRow = emlAuditColumn.firstLocaleRow
                    .badAuditText$ = emlAuditColumn.firstLocaleValue$
                endif
                if emlAuditColumn.nCoerced > 0
                    if .badAuditRow = 0
                    ... or emlAuditColumn.firstCoercedRow < .badAuditRow
                        .badAuditRow = emlAuditColumn.firstCoercedRow
                        .badAuditText$ = emlAuditColumn.firstCoercedValue$
                    endif
                endif
                # V1.7, cell ruling: this candidate no longer comes from
                # emlAuditColumn.nUnreadable / .firstUnreadableRow /
                # .firstUnreadableValue$, NOR from emlAuditColumn.nLeadingDot
                # / .firstLeadingDotRow / .firstLeadingDotValue$ -- those two
                # buckets between them count EVERY cell @eml_classifyCell
                # could not place in kind 0, 1, 2 or 4, including a
                # recognised missing-value placeholder (branch 1 of the cell
                # ruling exempts a placeholder wherever @eml_classifyCell
                # happened to file it, kind 5's bare-"." collision with
                # ".5"-style recovery included -- see
                # @eml_scanColumnForPlaceholders's header for why kind 5
                # cannot be trusted as a proxy for "genuinely bad").
                # .itemFirstGenuineBadRow[.i] / .itemFirstGenuineBadText$[.i]
                # (cached above, ahead of this loop, by
                # @eml_scanColumnForPlaceholders on this same column, which
                # now examines both buckets) already exclude every
                # placeholder from both, so they replace BOTH emlAuditColumn
                # candidates here rather than filtering either a second
                # time -- the classifier's whole verdict is still consumed,
                # just by the call site that now owns the "unreadable"
                # question for THIS column, not restated.
                if .itemFirstGenuineBadRow[.i] > 0
                    if .badAuditRow = 0
                    ... or .itemFirstGenuineBadRow[.i] < .badAuditRow
                        .badAuditRow = .itemFirstGenuineBadRow[.i]
                        .badAuditText$ = .itemFirstGenuineBadText$[.i]
                    endif
                endif

                if .badAuditRow > 0
                    .matchedScaleIdx = .itemScaleIndex[.i]
                    .error$ = .msg8a$ + .itemName$[.i] + .msg8b$
                    ... + .scaleName$[.matchedScaleIdx] + .msg8c$
                    ... + string$ (.badAuditRow) + .msg8d$
                    ... + .badAuditText$ + .msg8e$
                    .remedy$ = .rem8a$ + .itemName$[.i] + .rem8b$
                    ... + string$ (.badAuditRow) + .rem8c$ + .rem8d$
                    .refusal = 8
                    .badItem$ = .itemName$[.i]
                    .badScale$ = .scaleName$[.matchedScaleIdx]
                    .badRow = .badAuditRow
                    .badCellText$ = .badAuditText$
                    goto SURVEY_VALIDATE_DONE
                endif
            endif
        endif
    endfor

    # ===== Refusal 2: a data value outside its subscale's declared range =====
    # Every item's column is now known to exist (refusal 1 passed), so
    # "Get value:" below addresses a real column. Only items whose role
    # resolves to a declared scale are checked here; a role that resolves
    # to nothing is refusal 5's question, not this one, and is left alone.
    for .i from 1 to .nItems
        .role$ = .itemRole$[.i]
        .matched = 0
        for .s from 1 to .nScales
            if .role$ = .scaleName$[.s]
                .matched = 1
                .sMin = .scaleMin[.s]
                .sMax = .scaleMax[.s]
            endif
        endfor
        if .matched = 1
            for .r from 1 to .nData
                selectObject: .dataTableId
                .val = Get value: .r, .itemName$[.i]
                if .val <> undefined
                    if .val < .sMin or .val > .sMax
                        .error$ = .msg2a$ + string$ (.r) + .msg2b$
                        ... + .itemName$[.i] + .msg2c$ + .role$ + .msg2d$
                        ... + string$ (.val) + .msg2e$ + string$ (.sMin)
                        ... + .msg2f$ + string$ (.sMax) + .msg2g$
                        .remedy$ = .rem2a$ + string$ (.r) + .rem2b$
                        ... + .role$ + .rem2c$
                        .refusal = 2
                        .badItem$ = .itemName$[.i]
                        .badScale$ = .role$
                        .badRow = .r
                        .badValue = .val
                        .badMin = .sMin
                        .badMax = .sMax
                        goto SURVEY_VALIDATE_DONE
                    endif
                endif
            endfor
        endif
    endfor

    # ===== Refusal 3: a subscale with fewer than two items =====
    # Deliberately >= 1 here, not just < 2: a scale with ZERO items is not
    # "too few items to compute reliability on", it is refusal 5 direction
    # B below -- the scales file declaring a subscale the items file never
    # uses. Folding count = 0 into this refusal would make that direction
    # of refusal 5 unreachable (a scale nobody uses always has 0 items, so
    # this check would claim it first, every time), which is exactly the
    # dead-code trap: the plan (SURVEY_MODULE_PLAN_2026-08-25.md) pins these
    # as two named refusals, each needing its own seeded red demo, and a
    # refusal that can never fire cannot be demonstrated red.
    for .s from 1 to .nScales
        .count = 0
        for .i from 1 to .nItems
            if .itemRole$[.i] = .scaleName$[.s]
                .count = .count + 1
            endif
        endfor
        if .count >= 1 and .count < 2
            .error$ = .msg3a$ + .scaleName$[.s] + .msg3b$ + string$ (.count)
            ... + .msg3c$
            .remedy$ = .rem3a$ + .scaleName$[.s] + .rem3b$
            ... + .scaleName$[.s] + .rem3c$
            .refusal = 3
            .badScale$ = .scaleName$[.s]
            .scaleItemCount = .count
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 4: reversed flag set on a grouping or ignore column =====
    for .i from 1 to .nItems
        if .itemReversed[.i] = 1
            if .itemRole$[.i] = "grouping" or .itemRole$[.i] = "ignore"
                .error$ = .msg4a$ + .itemName$[.i] + .msg4b$
                ... + .itemRole$[.i] + .msg4c$
                .remedy$ = .rem4a$ + .itemName$[.i] + .rem4b$
                .refusal = 4
                .badItem$ = .itemName$[.i]
                .badRole$ = .itemRole$[.i]
                goto SURVEY_VALIDATE_DONE
            endif
        endif
    endfor

    # ===== Refusal 5: scales file and items file disagree on subscale =====
    # ===== names, checked in both directions                          =====

    # Direction A: an item names a scale the scales file lacks.
    for .i from 1 to .nItems
        .role$ = .itemRole$[.i]
        if .role$ <> "grouping" and .role$ <> "ignore"
            .matched = 0
            for .s from 1 to .nScales
                if .role$ = .scaleName$[.s]
                    .matched = 1
                endif
            endfor
            if .matched = 0
                .error$ = .msg5aA$ + .itemName$[.i] + .msg5aB$ + .role$
                ... + .msg5aC$
                .remedy$ = .rem5aA$ + .role$ + .rem5aB$ + .itemName$[.i]
                ... + .rem5aC$
                .refusal = 5
                .badItem$ = .itemName$[.i]
                .badScale$ = .role$
                .badDirection$ = "item_unknown_scale"
                goto SURVEY_VALIDATE_DONE
            endif
        endif
    endfor

    # Direction B: a declared scale that no item uses.
    for .s from 1 to .nScales
        .used = 0
        for .i from 1 to .nItems
            if .itemRole$[.i] = .scaleName$[.s]
                .used = 1
            endif
        endfor
        if .used = 0
            .error$ = .msg5bA$ + .scaleName$[.s] + .msg5bB$
            .remedy$ = .rem5bA$ + .scaleName$[.s] + .rem5bB$
            ... + .scaleName$[.s] + .rem5bC$
            .refusal = 5
            .badScale$ = .scaleName$[.s]
            .badDirection$ = "scale_unused"
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    label SURVEY_VALIDATE_DONE
endproc

# ============================================================================
# Outputs: @emlSurveyValidateDeclaration
# ============================================================================
# THE RULE, stated once (V1.6, Fix 1): every output documented below holds a
# DEFINED value on every return of this procedure -- including every one of
# the eighteen exit paths (SURVEY_VALIDATE_DONE reached by any of refusals
# 1-17, or by none) -- never an indexed variable left unassigned for a
# caller to hit an "Undefined indexed variable" halt by reading it.
#
#   .error$           - refusal message (rule + reason), or "" when the
#                       declaration is sound
#   .remedy$          - what to do instead, or "" when .error$ is ""
#   .refusal          - 0 when sound; else 1-17 (see the ordering comment
#                       above the procedure for what each is and the order
#                       they are checked in; refusal 10 is a contract
#                       repair, not one of Ian's original five or the four
#                       probed additions; refusals 11-14 are a second
#                       adversarial pass closing the same class of fault
#                       on the scales file that 6-10 closed on the items
#                       file; refusals 15-16 are a third adversarial pass
#                       closing two unchecked directions on the data
#                       table itself; refusal 17 is the Stage 3 ruling's
#                       underscore-normalized-name collision guard)
#   .badItem$         - the item/column name implicated (refusals 1, 2, 4,
#                       6, 7, 8, 15 [the repeated data-table header], 16
#                       [the undeclared data-table column], and refusal 5
#                       direction A); "" otherwise
#   .badScale$        - the subscale name implicated (refusals 2, 3, 8, 9,
#                       10, 12, 13, 17 [the LATER of the two colliding raw
#                       names -- see .error$/.remedy$ for both], and
#                       refusal 5, either direction); "" otherwise
#                       (refusal 14 leaves this "" too -- the fault IS that
#                       the scale has no name)
#   .badRow           - respondent ROW NUMBER in the data table (refusals 2
#                       and 8); 0 otherwise
#   .badValue         - the offending response value (refusal 2 only);
#                       undefined otherwise
#   .badMin           - the declared range minimum for .badScale$
#                       (refusals 2 and 10); undefined otherwise
#   .badMax           - the declared range maximum for .badScale$
#                       (refusals 2 and 10); undefined otherwise
#   .scaleItemCount   - number of items declared with role .badScale$
#                       (refusal 3 only); undefined otherwise
#   .badRole$         - the disallowed role ("grouping" or "ignore") found
#                       on a reversed item (refusal 4 only); "" otherwise
#   .badDirection$    - which side of refusal 5 fired: "item_unknown_scale"
#                       or "scale_unused"; "" otherwise
#   .badReversedValue - the illegal `reversed` value found (refusal 6
#                       only); undefined otherwise
#   .badItemRow       - ROW NUMBER in the ITEMS table implicated (refusal 7:
#                       the row of the repeated item name; refusal 6: the
#                       row holding the illegal `reversed` value); 0
#                       otherwise. Not the same table as .badRow, which is
#                       always a DATA table row.
#   .badScaleRow      - ROW NUMBER in the SCALES table implicated (refusals
#                       9, 10, 12, 13 [the duplicate row], 14, and 17 [the
#                       later of the two colliding rows]); 0 otherwise
#   .badTypeValue$    - the illegal `type` string found (refusal 9 only);
#                       "" otherwise
#   .badCellText$     - the literal (non-numeric) contents of the offending
#                       cell (refusal 8 only); "" otherwise
#   .badColumn$       - the column name implicated (refusal 11: the missing
#                       required column; refusal 12: "min" or "max",
#                       whichever declared endpoint is bad); "" otherwise
#   .badFile$         - which declaration file is at fault, "survey_items.csv"
#                       or "survey_scales.csv" (refusal 11 only); ""
#                       otherwise
#   .badRawValue$     - the literal declared text of the bad endpoint cell
#                       (refusal 12 only); "" when refusal is not 12, and
#                       "" (V1.6, Fix 1, header defect b: forced, not just
#                       reported as-is) whenever that cell reads as EMPTY --
#                       a genuinely blank cell, Praat's own missing-value
#                       token "--undefined--", or a whitespace-only cell
#                       (@eml_classifyCell's kind 1 folds all three
#                       together) -- rather than a non-numeric one. Exists
#                       so a caller can name the actual offending text
#                       without ever printing the internal token
#                       "--undefined--" for it, including a caller that
#                       reads this field directly rather than only
#                       .error$'s sentence.
#   .scaleName$[1..nScales]  - each declared subscale's name, in
#                       survey_scales.csv row order
#   .scaleType$[1..nScales]  - each declared subscale's `type` field, as
#                       declared (not validated against the type-keyword
#                       canon until refusal 9 runs)
#   .scaleMin[1..nScales], .scaleMax[1..nScales] - each declared subscale's
#                       printed response range, as declared
#   .scaleIsKR20[1..nScales] - 1 when that subscale's declared range spans
#                       exactly two values (max = min + 1), 0 otherwise, OR
#                       (V1.6, Fix 1, header defect c: documented, not
#                       patched into a fake 0 or 1) `undefined` for EVERY
#                       scale specifically on the refusal-11 path -- the
#                       one path where the scales-population loop that
#                       computes this from min/max never runs, so there is
#                       no confirmed range yet to name a naming condition
#                       about, only the same seeded placeholder the other
#                       four per-scale array outputs above carry on that
#                       same path. THE KR-20 naming condition, stated once
#                       in this procedure and not restated anywhere else --
#                       Stage 2 reads this rather than re-deriving it from
#                       min/max itself. Meaningful only once .refusal is
#                       confirmed 0 for the declaration as a whole; a scale
#                       that fails refusal 9, 10, or 12 still gets a real
#                       0/1 entry here (computed from whatever it
#                       declared), but that entry is moot once the
#                       declaration itself is refused -- refusal 11 is the
#                       one exception, where even a real 0/1 was never
#                       computed at all.
#   .nScales          - number of declared subscales (length of the four
#                       arrays immediately above)
#   .disclosureCount  - [V1.7, cell ruling] count of respondent cells, in
#                       ANY subscale item's data column, that hold a
#                       recognised missing-value placeholder
#                       (@emlRepairClassify's own kind-3 spellings,
#                       eml-extract.praat:2665 -- not restated here); 0
#                       when none were found. Set by a pass that always
#                       runs before refusal 8 and is NEVER skipped by a
#                       `goto` out of it, so this is meaningful even when
#                       .refusal ends up nonzero (refusal 8 itself, on a
#                       DIFFERENT cell in the same or another item's
#                       column, or refusal 2 below it) -- a placeholder
#                       found earlier in this same pass is disclosed
#                       regardless of what the declaration is ultimately
#                       refused for. 0 on every exit BEFORE this pass runs
#                       (refusals 1, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16 --
#                       all pure declaration-shape faults decided before
#                       any subscale item's data column is read here).
#   .disclosureSpellingCount, .disclosureItemCount - [V1.7] length of the
#                       two arrays immediately below; both 0 exactly when
#                       .disclosureCount is 0
#   .disclosureSpelling$[1..disclosureSpellingCount] - [V1.7] each DISTINCT
#                       placeholder spelling found, trimmed, in first-
#                       encountered order (case preserved as declared --
#                       "NA" and "na" are two entries, not one). Index 1
#                       specifically is DEFINED on every return, even when
#                       .disclosureSpellingCount is 0 -- seeded to "" at
#                       procedure entry (the same reason .scaleName$[1] is
#                       never left to halt a reader on the refusal-11
#                       path: an unassigned indexed variable HALTS), and
#                       overwritten with the real first spelling only when
#                       one is found. Reading index 1 is therefore always
#                       safe; "" at index 1 means no placeholder was found.
#   .disclosureItem$[1..disclosureItemCount] - [V1.7] each subscale item
#                       (data column name) that had at least one
#                       placeholder cell, in first-encountered order. Index
#                       1 carries the same always-defined guarantee as
#                       .disclosureSpelling$[1], above, for the same
#                       reason.
#   .disclosure$      - [V1.7] the assembled sentence naming all three
#                       facts above, already PRINTED (appendInfoLine)
#                       whenever .disclosureCount > 0; "" exactly when
#                       .disclosureCount is 0, the same empty-exactly-
#                       when-nothing-to-say contract .error$/.remedy$
#                       already keep. DRAFT wording, awaiting Ian's
#                       approval like every other message this procedure
#                       builds -- callers should read .disclosureCount /
#                       .disclosureSpelling$[] / .disclosureItem$[]
#                       directly rather than parse this sentence.
#
# Access pattern:
#   @emlSurveyValidateDeclaration: dataTable, scalesTable, itemsTable
#   if emlSurveyValidateDeclaration.error$ <> ""
#       code = emlSurveyValidateDeclaration.refusal
#       ... report emlSurveyValidateDeclaration.error$ and .remedy$ ...
#   endif
#   ... once refusal = 0, read the KR-20 condition without re-deriving it:
#   isKR20 = emlSurveyValidateDeclaration.scaleIsKR20[3]
#
# Notes:
#   - Read-only: no cell in any of the three tables is written, and no
#     file is read or written here (the caller reads the two CSVs into
#     Tables with "Read Table from comma-separated file..." first).
#   - Does not compute reversal, subscale routing, or any reliability
#     statistic. Those are Stage 2, wired on top of a clean declaration.
#   - Leaves SOME declaration Table selected on return -- whichever one the
#     last check to run happened to touch -- matching
#     @emlRequireColumnPresent's convention of leaving a Table selected
#     rather than the caller's, but WHICH Table is no longer a fixed
#     answer as of V1.3 (refusal 7's refactor onto @eml_findDuplicateName
#     leaves .itemsTableId selected even when 7 itself does not fire, so a
#     later refusal such as 9 or 10 no longer inherits .dataTableId the
#     way it did before V1.3; V1.5's refusal 15 goes further still,
#     briefly selecting and then removing a scratch Table of its own that
#     never existed before this procedure ran, so a refusal-15 return in
#     particular may leave nothing meaningful selected at all). A caller
#     that needs a specific Table selected should select it itself rather
#     than rely on this
#     procedure's leftover selection.
#   - [V1.8] .nItems, .itemName$[], .itemRole$[], .itemReversed[], and
#     .itemScaleIndex[] are internal working state, NOT part of the
#     guaranteed-output contract above (they are deliberately left out of
#     the "# Outputs:" block v129_survey_declaration.R's exhaustive
#     output-contract sweep enforces on EVERY refusal path, Gate 1's own
#     verified scope, which this addition does not reopen) -- they are
#     populated only from the items-table read loop onward, so they are
#     UNDEFINED / UNSAFE on a refusal-11 return specifically, and
#     .itemScaleIndex[] is unsafe on a refusal-15 return too (both exit
#     before the loop that fills it). @emlSurveyScoreScales (below) is the
#     one caller that reads them, and only under its own documented
#     precondition (.refusal confirmed 0), where the items-table read loop
#     and the .itemScaleIndex[] loop have both already run unconditionally
#     -- so they are always safely populated at the one point Stage 2 ever
#     reads them, without this module promising more than that.
# ============================================================================

# ============================================================================
# @eml_reverseScoreMatrix (V1.8)
# ============================================================================
# THE REVERSAL TRANSFORM, in one place: y = min + max - x, applied to every
# item whose declared `reversed` is 1; every other item passes through
# unchanged. min/max are the SUBSCALE's declared printed range (not the
# observed range -- v130's own header explains why alpha cannot tell the
# two apart, but the scale-score MEAN can and does, which is the reason the
# declared range still has to be threaded all the way through here).
#
# Matrix in, matrix out, vectorized (CLAUDE.md: a per-element Get/Set loop
# is 100-400x slower, not untidy): each reversed column is `sign = -1`,
# `offset = min + max`; each forward column is `sign = 1`, `offset = 0`;
# the whole matrix is built in one elementwise multiply and one elementwise
# add, broadcasting the two per-column vectors down every row with
# `outer##` -- the same broadcasting idiom @emlCronbachAlpha already uses
# to center a matrix by its column means, a few hundred lines above. An
# undefined cell (already-missing, or a placeholder the declaration
# validator's cell ruling folded into ordinary missingness) stays
# undefined: arithmetic with undefined propagates in Praat (the same fact
# @eml_listwiseComplete's own header already leans on), so no special case
# is needed here for a missing cell in a reversed column.
#
# Input:  .raw##         - numeric matrix, rows = respondents, columns =
#                           items, in the subscale's declared item order
#         .min, .max      - the subscale's declared printed range
#         .reversedFlag#  - numeric vector, length = numberOfColumns(.raw##);
#                           1 for a reversed item, 0 otherwise, in the SAME
#                           column order as .raw##
# Output: .scored##       - the reverse-scored matrix, same shape as .raw##
# ----------------------------------------------------------------------------
procedure eml_reverseScoreMatrix: .raw##, .min, .max, .reversedFlag#
    .nRows = numberOfRows (.raw##)
    .nCols = numberOfColumns (.raw##)
    .sign# = zero# (.nCols)
    .offset# = zero# (.nCols)
    for .j from 1 to .nCols
        if .reversedFlag# [.j] = 1
            .sign# [.j] = -1
            .offset# [.j] = .min + .max
        else
            .sign# [.j] = 1
            .offset# [.j] = 0
        endif
    endfor
    .ones# = zero# (.nRows) + 1
    .scored## = .raw## * outer## (.ones#, .sign#) + outer## (.ones#, .offset#)
endproc

# ============================================================================
# @emlSurveyScoreScales (V1.8)
# ============================================================================
# THE COMPUTATIONAL HALF OF STAGE 2: per-subscale routing, the reversal
# transform, both reliability kernels, item-rest/item-total, and the
# per-respondent scale scores -- driven entirely by the declaration
# @emlSurveyValidateDeclaration already produced, not by re-deriving it. No
# report text and no dialog live here; the next stage owns presentation.
#
# PRECONDITION, NOT RE-CHECKED HERE: the caller has already run
#   @emlSurveyValidateDeclaration: dataTableId, scalesTableId, itemsTableId
# on the SAME .dataTableId passed in below, and confirmed
# emlSurveyValidateDeclaration.refusal = 0. This procedure reads that call's
# own leftover namespace directly -- .nScales, .scaleName$[], .scaleMin[],
# .scaleMax[], .scaleIsKR20[], .nItems, .itemName$[], .itemRole$[],
# .itemReversed[], .itemScaleIndex[], .nData -- exactly the "driven by the
# declaration the validator already produces" the task describes, rather
# than re-reading the three Tables and re-resolving which item belongs to
# which subscale a second time (@emlSurveyValidateDeclaration's own
# .itemScaleIndex[] already answers that, refusal 8's own call site). A
# caller that has not just run a clean declaration over .dataTableId gets
# whatever @emlSurveyValidateDeclaration last left behind, which is exactly
# the same "outputs survive only until that procedure runs again" contract
# every other @eml-prefixed call in this codebase already carries
# (CLAUDE.md) -- nothing new is being risked here that a caller does not
# already have to respect for @emlAuditColumn, @eml_classifyCell, or any
# other helper this module calls.
#
# THE CONFIDENCE LEVEL, from @emlReportAlpha (eml-analysis.praat), NEVER A
# LITERAL, structurally: this procedure takes no .confidence argument at
# all, so there is no parameter for a caller to pass a hardcoded number
# into. It calls @emlReportAlpha itself, once, at the top, and every
# subscale's Feldt interval is computed at the SAME resulting level
# (.confidence, echoed as this procedure's own output) -- one call, one
# level, applied uniformly by the indexed loop below rather than re-read
# per subscale.
#
# ONE SUBSCALE FAILING DOES NOT KILL THE RUN, structurally, not as a
# special case: the loop below runs the IDENTICAL sequence of steps for
# every subscale s = 1 to .nScales, with no branch anywhere on "did an
# earlier subscale fail". @emlCronbachAlpha and @emlAlphaInfluence already
# guarantee their own contract -- every numeric output stays a safely
# readable `undefined` and .error$ names the reason whenever their own
# preconditions (k >= 2, n >= 3 after listwise deletion) are not met -- so
# a subscale with, say, only two complete respondents simply leaves
# .subAlpha[s] / .subCiLow[s] / .subCiHigh[s] / .subAlphaIfDeleted[s,*] at
# their seeded `undefined` and .subAlphaError$[s] non-empty, while every
# OTHER subscale's iteration of this same for-loop is untouched: nothing
# here `goto`s out of the loop, and nothing conditions later iterations on
# an earlier one's result. THE REFUSAL IS A RESULT: it is carried
# VERBATIM, in .subAlphaError$[s] / .subInfluenceError$[s], exactly as
# @emlCronbachAlpha / @emlAlphaInfluence wrote it, never reworded here.
#
# THE REVERSAL TRANSFORM uses the subscale's DECLARED printed range
# (@eml_reverseScoreMatrix, above), matching "Alpha and its whole family
# are invariant to the declared endpoints" (v130's own algebraic proof:
# alpha is a pure function of the covariance matrix, and Cov(c - x, y) =
# -Cov(x, y) for any constant c = min + max, so only the SIGN of the
# transform -- whether an item is reversed at all -- reaches alpha,
# alpha-if-deleted, item-rest, or item-total). The declared range reaches
# a result only through the validator's own range refusal and through the
# scale-score MEAN below, which sits on the printed response scale rather
# than in the covariance structure.
#
# ITEM-REST AND ITEM-TOTAL, both through @emlPearsonCorrelation
# (eml-inferential.praat), computed on the SAME reverse-scored,
# listwise-complete matrix @emlCronbachAlpha itself works from (built once,
# here, via the same @eml_listwiseComplete this module's own alpha kernel
# calls -- not a second, differently-cleaned copy): item-rest is item j
# against the sum of the OTHER items in its subscale (row total minus
# column j); item-total is item j against the row total, uncorrected
# (including j). Both are carried as raw values; the strictly-below-zero
# item-rest flag (the misdeclared-reversal ruling) is computed here too,
# .subItemFlag[s,j], but printing it is the report layer's job, not this
# one's. @emlPearsonCorrelation's own preconditions (n >= 3 pairs, nonzero
# variance in both variables) are consumed by reading its .error$: an item
# column that happens to be constant within an otherwise-scorable subscale
# leaves that one item's two correlations at their seeded `undefined`
# without disturbing any other item or the subscale's alpha.
#
# SCALE SCORES: a respondent's subscale score is the MEAN (not the sum --
# "so scores compare across subscales of different lengths", the task's
# own words) of that subscale's reverse-scored items, complete-case: a
# respondent missing ANY item in the subscale gets no score for it. This
# uses the identical complete-case mask alpha and the correlations use
# (@eml_listwiseComplete's .clean##), so .subScoredN[s] always equals
# .subN[s] when the alpha kernel succeeds, and is meaningful on its own
# even when it does not (a two-respondent subscale still scores those two
# respondents; it is @emlCronbachAlpha's n >= 3 floor that refuses, not
# this computation's own). .subScoredNone[s] carries the count with no
# score, for disclosure, per the task's own wording ("the count with no
# score is carried for disclosure").
#
# THE KR-20 CONDITION is carried, not recomputed: .subIsKR20[s] is a plain
# copy of emlSurveyValidateDeclaration.scaleIsKR20[s], assigned once per
# subscale alongside every other seeded output, never re-derived from
# min/max a second time in this procedure.
#
# Input:  .dataTableId - the SAME data Table just validated (see
#                         PRECONDITION above)
#
# Output (all seeded to a defined placeholder for every subscale before any
# subscale is processed -- V1.6 Fix 1's rule, restated: every documented
# output holds a defined value once this procedure returns):
#   .confidence            - the Feldt/scale-score confidence level, from
#                             @emlReportAlpha, applied to every subscale
#   .nScales                - convenience echo of
#                             emlSurveyValidateDeclaration.nScales; every
#                             array below is indexed 1..nScales unless
#                             stated otherwise
#   .subK[1..nScales]       - item count actually assembled for that
#                             subscale (equals .scaleItemCount's live
#                             analogue; always >= 2, refusal 3's own floor)
#   .subAlpha[], .subCiLow[], .subCiHigh[] - @emlCronbachAlpha's own
#                             outputs, or `undefined` when it refused
#   .subN[], .subNExcluded[] - complete-case n and rows dropped, from
#                             @emlCronbachAlpha (equal to .subScoredN[] /
#                             .subScoredNone[] below, since both read the
#                             same listwise-complete matrix)
#   .subAlphaError$[]       - @emlCronbachAlpha.error$ VERBATIM; "" when it
#                             did not refuse
#   .subAlphaIfDeleted[s, 1..subK[s]] - @emlCronbachAlpha's own
#                             .alphaIfDeleted#, one column per subscale
#                             item in declared order; `undefined` for
#                             every item when subK[s] = 2 (no alpha to
#                             drop to) or when the subscale's kernel
#                             refused
#   .subDeltaMax[], .subDeltaMaxRow[] - @emlAlphaInfluence's own outputs
#                             (ORIGINAL row number within THIS subscale's
#                             own complete-case matrix -- listwise
#                             deletion differs per subscale, so the same
#                             respondent can carry a different original
#                             row number in two different subscales'
#                             influence output)
#   .subInfluenceError$[]   - @emlAlphaInfluence.error$ VERBATIM; "" when
#                             it did not refuse
#   .subAlphaWithout[s, 1..subN[s]], .subDelta[s, 1..subN[s]],
#   .subRowIndex[s, 1..subN[s]] - @emlAlphaInfluence's own per-respondent
#                             vectors, re-indexed [subscale, surviving
#                             respondent position]; `undefined` beyond
#                             subN[s] and for every entry when the
#                             subscale's influence kernel refused
#   .subItemRest[s, 1..subK[s]], .subItemTotal[s, 1..subK[s]] - each
#                             item's item-rest and uncorrected item-total
#                             correlation (raw r); `undefined` when that
#                             one item's correlation could not be computed
#                             (@emlPearsonCorrelation's own preconditions)
#   .subItemFlag[s, 1..subK[s]] - 1 when that item's item-rest is strictly
#                             below zero (the misdeclared-reversal
#                             ruling), 0 otherwise; `undefined` exactly
#                             when .subItemRest[s, j] is
#   .subItemOrigIdx[s, 1..subK[s]] - the ORIGINAL index into
#                             emlSurveyValidateDeclaration.itemName$[] /
#                             .itemReversed[] for subscale-position j, so
#                             a caller reads the item's name/reversed flag
#                             from the declaration's own arrays rather
#                             than a second copy kept here
#   .subScoredN[], .subScoredNone[] - respondents scored / with no score
#                             for that subscale (counts only -- never the
#                             individual scores, per the task's own
#                             wording)
#   .subScoreMean[], .subScoreSD[], .subScoreMin[], .subScoreMax[] -
#                             summary statistics of the per-respondent
#                             scale score (the MEAN of that respondent's
#                             reverse-scored items), complete-case;
#                             `undefined` when .subScoredN[s] is 0
#                             (Mean/Min/Max) or below 2 (SD, which needs
#                             at least two respondents to have a spread)
#   .subIsKR20[]            - plain copy of
#                             emlSurveyValidateDeclaration.scaleIsKR20[s];
#                             not recomputed
#
# Access pattern:
#   @emlSurveyValidateDeclaration: dataT, scalesT, itemsT
#   if emlSurveyValidateDeclaration.refusal = 0
#       @emlSurveyScoreScales: dataT
#       a3 = emlSurveyScoreScales.subAlpha[3]
#       flaggedQ3 = emlSurveyScoreScales.subItemFlag[1, 3]
#   endif
#
# Notes:
#   - Read-only on .dataTableId: no cell is written, no Table object is
#     created or removed (unlike @emlSurveyValidateDeclaration's refusal
#     15, which briefly creates and removes a scratch Table).
#   - Requires @emlReportAlpha (eml-analysis.praat) in addition to this
#     module's existing Dependencies (eml-extract.praat, eml-inferential.
#     praat). @emlReportAlpha itself has no further dependency of its own
#     (built-ins only), so this is the one additional include a caller of
#     THIS procedure needs beyond @emlSurveyValidateDeclaration's own list:
#       include eml-extract.praat
#       include eml-inferential.praat
#       include eml-analysis.praat
#       include eml-psychometrics.praat
# ============================================================================
procedure emlSurveyScoreScales: .dataTableId
    @emlReportAlpha
    .confidence = 1 - emlReportAlpha.value

    .nScales = emlSurveyValidateDeclaration.nScales
    .nItemsDeclared = emlSurveyValidateDeclaration.nItems
    .nData = emlSurveyValidateDeclaration.nData

    # --- Every per-subscale / per-item output, seeded before any subscale
    # is processed (V1.6 Fix 1's rule, restated for Stage 2): a subscale
    # whose kernel refuses must leave every array a caller can still read,
    # never an unassigned indexed variable. .maxK bounds the per-item
    # arrays' second index; .nData bounds the per-respondent ones.
    .maxK = 2
    for .s from 1 to .nScales
        .kCount = 0
        for .i from 1 to .nItemsDeclared
            if emlSurveyValidateDeclaration.itemScaleIndex[.i] = .s
                .kCount = .kCount + 1
            endif
        endfor
        if .kCount > .maxK
            .maxK = .kCount
        endif
    endfor

    for .s from 1 to .nScales
        .subK[.s] = 0
        .subAlpha[.s] = undefined
        .subCiLow[.s] = undefined
        .subCiHigh[.s] = undefined
        .subN[.s] = undefined
        .subNExcluded[.s] = undefined
        .subAlphaError$[.s] = ""
        .subInfluenceError$[.s] = ""
        .subDeltaMax[.s] = undefined
        .subDeltaMaxRow[.s] = undefined
        .subIsKR20[.s] = emlSurveyValidateDeclaration.scaleIsKR20[.s]
        .subScoredN[.s] = 0
        .subScoredNone[.s] = .nData
        .subScoreMean[.s] = undefined
        .subScoreSD[.s] = undefined
        .subScoreMin[.s] = undefined
        .subScoreMax[.s] = undefined
        for .j from 1 to .maxK
            .subItemOrigIdx[.s,.j] = 0
            .subAlphaIfDeleted[.s,.j] = undefined
            .subItemRest[.s,.j] = undefined
            .subItemTotal[.s,.j] = undefined
            .subItemFlag[.s,.j] = undefined
        endfor
        for .r from 1 to .nData
            .subAlphaWithout[.s,.r] = undefined
            .subDelta[.s,.r] = undefined
            .subRowIndex[.s,.r] = undefined
        endfor
    endfor

    # --- Per-subscale routing: the SAME sequence of steps for every
    # subscale, indexed by .s -- no per-case code, no branch on an earlier
    # subscale's result (the "make this structural" requirement).
    for .s from 1 to .nScales
        # Assemble this subscale's items, in survey_items.csv row order
        # (the "declared order" the task asks for), via
        # emlSurveyValidateDeclaration.itemScaleIndex[] -- already computed
        # by the validator; not re-derived from .itemRole$[] here.
        .k = 0
        for .i from 1 to .nItemsDeclared
            if emlSurveyValidateDeclaration.itemScaleIndex[.i] = .s
                .k = .k + 1
                .subItemOrigIdx[.s,.k] = .i
            endif
        endfor
        .subK[.s] = .k

        .sMin = emlSurveyValidateDeclaration.scaleMin[.s]
        .sMax = emlSurveyValidateDeclaration.scaleMax[.s]
        .reversedFlag# = zero# (.k)
        .raw## = zero## (.nData, .k)
        for .j from 1 to .k
            .origIdx = .subItemOrigIdx[.s,.j]
            .reversedFlag# [.j] = emlSurveyValidateDeclaration.itemReversed[.origIdx]
            .colName$ = emlSurveyValidateDeclaration.itemName$[.origIdx]
            for .r from 1 to .nData
                selectObject: .dataTableId
                .raw## [.r,.j] = Get value: .r, .colName$
            endfor
        endfor

        @eml_reverseScoreMatrix: .raw##, .sMin, .sMax, .reversedFlag#
        .reversed## = eml_reverseScoreMatrix.scored##

        # The complete-case matrix @emlCronbachAlpha itself would build
        # internally -- built once, here, so item-rest/item-total and the
        # scale scores read exactly the same rows alpha did, not a second,
        # separately-cleaned copy.
        @eml_listwiseComplete: .reversed##
        .work## = eml_listwiseComplete.clean##
        .nKept = eml_listwiseComplete.nKept
        .nExcl = eml_listwiseComplete.nExcluded

        @emlCronbachAlpha: .reversed##, .confidence
        .subAlphaError$[.s] = emlCronbachAlpha.error$
        .subN[.s] = emlCronbachAlpha.n
        .subNExcluded[.s] = emlCronbachAlpha.nExcluded
        if emlCronbachAlpha.error$ = ""
            .subAlpha[.s] = emlCronbachAlpha.alpha
            .subCiLow[.s] = emlCronbachAlpha.ciLow
            .subCiHigh[.s] = emlCronbachAlpha.ciHigh
            if .k >= 3
                for .j from 1 to .k
                    .subAlphaIfDeleted[.s,.j] = emlCronbachAlpha.alphaIfDeleted# [.j]
                endfor
            endif
        endif

        @emlAlphaInfluence: .reversed##
        .subInfluenceError$[.s] = emlAlphaInfluence.error$
        if emlAlphaInfluence.error$ = ""
            .subDeltaMax[.s] = emlAlphaInfluence.deltaMax
            .subDeltaMaxRow[.s] = emlAlphaInfluence.deltaMaxRow
            for .r from 1 to emlAlphaInfluence.n
                .subAlphaWithout[.s,.r] = emlAlphaInfluence.alphaWithout# [.r]
                .subDelta[.s,.r] = emlAlphaInfluence.delta# [.r]
                .subRowIndex[.s,.r] = emlAlphaInfluence.rowIndex# [.r]
            endfor
        endif

        # Item-rest / item-total and the scale scores both read .work##,
        # guarded only against an EMPTY complete-case matrix (nKept = 0),
        # not against @emlPearsonCorrelation's own n >= 3 floor -- that
        # floor is consumed via its own .error$ per item below, not
        # restated as a second condition here.
        if .nKept >= 1
            .total# = rowSums# (.work##)
            for .j from 1 to .k
                .unit# = zero# (.k)
                .unit# [.j] = 1
                .colJ# = mul# (.work##, .unit#)
                .rest# = .total# - .colJ#
                @emlPearsonCorrelation: .colJ#, .rest#, 2
                if emlPearsonCorrelation.error$ = ""
                    .subItemRest[.s,.j] = emlPearsonCorrelation.r
                    if emlPearsonCorrelation.r < 0
                        .subItemFlag[.s,.j] = 1
                    else
                        .subItemFlag[.s,.j] = 0
                    endif
                endif
                @emlPearsonCorrelation: .colJ#, .total#, 2
                if emlPearsonCorrelation.error$ = ""
                    .subItemTotal[.s,.j] = emlPearsonCorrelation.r
                endif
            endfor

            .scores# = .total# * (1 / .k)
            .subScoreMin[.s] = min (.scores#)
            .subScoreMax[.s] = max (.scores#)
            .subScoreMean[.s] = mean (.scores#)
            if .nKept >= 2
                .subScoreSD[.s] = stdev (.scores#)
            endif
        endif
        .subScoredN[.s] = .nKept
        .subScoredNone[.s] = .nExcl
    endfor
endproc

# ============================================================================
# @emlSurveySubscaleDisclosure (V1.9)
# ============================================================================
# THE PER-SUBSCALE SLICE OF THE CELL RULING'S GLOBAL DISCLOSURE. V1.7's
# @emlSurveyValidateDeclaration already scans every subscale item's data
# column once (@eml_scanColumnForPlaceholders, above) and prints one
# aggregated sentence for the DECLARATION AS A WHOLE, unconditionally,
# whenever any recognised missing-value placeholder cell was found anywhere
# in it. That answers "was anything in this run reinterpreted" -- correct
# for Stage 1, and not this procedure's job to repeat. It does not answer
# "was THIS subscale's own report affected, and by which of ITS items and
# spellings", which is what a per-subscale report block needs and the
# run-wide aggregate throws away (it keeps distinct spellings and affected
# item NAMES for the whole run, but not which spelling landed on which
# item, nor a per-item cell count).
#
# NOT a second classifier and NOT a restatement of @emlRepairClassify's
# kind-3 spelling list (which lives only at eml-extract.praat:2665): this
# calls @eml_scanColumnForPlaceholders again, once per item of the ONE
# subscale asked about -- the identical helper @emlSurveyValidateDeclaration
# itself already calls once per item of EVERY subscale. Calling it twice on
# the same column is safe and cheap: it is read-only (a loop of plain
# "Get value:" calls over the column), writes no cell, and creates no
# object, so nothing about calling it again disturbs
# @emlSurveyValidateDeclaration's own already-returned state.
#
# PRECONDITION, the same one @emlSurveyScoreScales documents: the caller has
# already run @emlSurveyValidateDeclaration on .dataTableId and confirmed
# .refusal = 0, and has already run @emlSurveyScoreScales on the same
# .dataTableId, so this subscale's own .subK[.s] / .subItemOrigIdx[.s,*]
# (V1.8) are populated. Walking THOSE arrays -- rather than re-deriving
# subscale membership from .itemScaleIndex[] a second, differently-ordered
# way -- is what keeps this in the declared item order the report already
# uses for every other per-item line.
#
# Input:  .dataTableId, .s   (subscale index, 1..emlSurveyScoreScales.nScales)
# Output: .count             - number of THIS subscale's items that had at
#                              least one recognised placeholder cell
#         .cellCount         - total placeholder CELLS across those items
#                              (may exceed .count: one item can hold several)
#         .item$[1..count]   - those item names, in declared order
#         .spellingCount, .spelling$[1..spellingCount] - distinct spellings
#                              found within THIS subscale's own items only
#                              (a subset of, or equal to,
#                              emlSurveyValidateDeclaration.
#                              disclosureSpelling$[] for the run as a whole)
#
# Notes:
#   - .count is 0, .cellCount is 0 and .spellingCount is 0 -- never left
#     undefined -- for a subscale none of whose items carried a placeholder,
#     the same "seed a safe zero, never an unassigned indexed variable"
#     discipline every other output in this module already keeps.
#   - Read-only; no report text; the caller formats.
# ----------------------------------------------------------------------------
procedure emlSurveySubscaleDisclosure: .dataTableId, .s
    .count = 0
    .cellCount = 0
    .spellingCount = 0
    for .j from 1 to emlSurveyScoreScales.subK[.s]
        .origIdx = emlSurveyScoreScales.subItemOrigIdx[.s, .j]
        .colName$ = emlSurveyValidateDeclaration.itemName$[.origIdx]
        @eml_scanColumnForPlaceholders: .dataTableId, .colName$,
        ... emlSurveyScoreScales.nData
        if eml_scanColumnForPlaceholders.nPlaceholder > 0
            .count = .count + 1
            .item$[.count] = .colName$
            for .p from 1 to eml_scanColumnForPlaceholders.nPlaceholder
                .cellCount = .cellCount + 1
                .pText$ = eml_scanColumnForPlaceholders.placeholderText$[.p]
                .seen = 0
                for .q from 1 to .spellingCount
                    if .spelling$[.q] = .pText$
                        .seen = 1
                    endif
                endfor
                if .seen = 0
                    .spellingCount = .spellingCount + 1
                    .spelling$[.spellingCount] = .pText$
                endif
            endfor
        endif
    endfor
endproc

# ============================================================================
# END OF MODULE
# ============================================================================
