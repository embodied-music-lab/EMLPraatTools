# ============================================================================
# EML Stats & Graphs — Linear Mixed Models
# ============================================================================
# File: eml-lmm.praat
# Version: 0.8 (Satterthwaite/KR/R²/PhiA fixes — full lme4+pbkrtest parity)
# Date: 17 May 2026
#
# License: GPL-3.0-or-later
#
# Provides linear mixed-effects model (LMM) fitting equivalent to R's
# lme4::lmer(). Depends on eml-linalg.praat and eml-optimizer.praat.
#
# Procedures:
#   @emlParseFormula        — Parse R-style formula string
#   @emlContrastMatrix      — Generate contrast coding matrix
#   @emlModelMatrix         — Build fixed-effects design matrix X
#   @emlRandomEffectsZ      — Build random-effects Z + Lambda template
#   @emlConstructLambda     — theta → block-diagonal Lambda
#   @emlProfiledDeviance    — Objective function for BOBYQA
#   @emlRecoverBetaSigma    — Extract beta, sigma at optimal theta
#   @emlLMM                 — Main fitting entry point
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

# ============================================================================
# UTILITY: @emlTrimWhitespace
# Strip leading and trailing spaces from a string
# ============================================================================
procedure emlTrimWhitespace: .s$
    .result$ = replace_regex$ (.s$, "^ +", "", 0)
    .result$ = replace_regex$ (.result$, " +$", "", 0)
endproc

# ============================================================================
# UTILITY: @emlSplitTerms
# Split a string by a delimiter, respecting parenthesized groups.
# Produces .n terms in .term'.i'$
# ============================================================================
procedure emlSplitTerms: .s$, .delim$
    .n = 0
    .depth = 0
    .current$ = ""
    .len = length (.s$)
    for .pos from 1 to .len
        .ch$ = mid$ (.s$, .pos, 1)
        if .ch$ = "("
            .depth = .depth + 1
            .current$ = .current$ + .ch$
        elsif .ch$ = ")"
            .depth = .depth - 1
            .current$ = .current$ + .ch$
        elsif .ch$ = .delim$ and .depth = 0
            .n = .n + 1
            @emlTrimWhitespace: .current$
            .term'.n'$ = emlTrimWhitespace.result$
            .current$ = ""
        else
            .current$ = .current$ + .ch$
        endif
    endfor
    # Last term
    if .current$ <> ""
        .n = .n + 1
        @emlTrimWhitespace: .current$
        .term'.n'$ = emlTrimWhitespace.result$
    endif
endproc

# ============================================================================
# UTILITY: @emlExpandCrossing
# Expand A*B into {A, B, A:B}. Handles multi-way: A*B*C etc.
# Input: .term$ (e.g. "A*B*C")
# Output: .n expanded terms in .term'.i'$
# ============================================================================
procedure emlExpandCrossing: .term$
    # Split on *
    @emlSplitTerms: .term$, "*"
    .nFactors = emlSplitTerms.n
    if .nFactors = 1
        .n = 1
        .term1$ = .term$
        goto END_EXPAND_CROSS
    endif

    # Collect factor names
    for .f from 1 to .nFactors
        .factor'.f'$ = emlSplitTerms.term'.f'$
    endfor

    # Generate all subsets of size 1 to nFactors
    # Total subsets = 2^nFactors - 1
    .n = 0
    .nSubsets = 2 ^ .nFactors - 1
    for .mask from 1 to .nSubsets
        .n = .n + 1
        .term'.n'$ = ""
        .remaining = .mask
        for .bit from 1 to .nFactors
            .hasBit = .remaining mod 2
            .remaining = floor (.remaining / 2)
            if .hasBit = 1
                if .term'.n'$ <> ""
                    .term'.n'$ = .term'.n'$ + ":"
                endif
                .term'.n'$ = .term'.n'$ + .factor'.bit'$
            endif
        endfor
    endfor

    label END_EXPAND_CROSS
endproc

# ============================================================================
# UTILITY: @emlExpandDegree
# Expand (A+B+C)^n — all interactions up to degree n.
# Input: .terms$# (base terms), .nTerms, .degree
# Output: .n expanded terms in .term'.i'$
# ============================================================================
procedure emlExpandDegree: .nBase, .degree
    # .baseTerm'.i'$ must be set by caller
    .n = 0
    .nSubsets = 2 ^ .nBase - 1
    for .mask from 1 to .nSubsets
        # Count bits (= interaction order)
        .order = 0
        .tmp = .mask
        for .bit from 1 to .nBase
            .order = .order + (.tmp mod 2)
            .tmp = floor (.tmp / 2)
        endfor
        if .order <= .degree
            .n = .n + 1
            .term'.n'$ = ""
            .remaining = .mask
            for .bit from 1 to .nBase
                .hasBit = .remaining mod 2
                .remaining = floor (.remaining / 2)
                if .hasBit = 1
                    if .term'.n'$ <> ""
                        .term'.n'$ = .term'.n'$ + ":"
                    endif
                    .term'.n'$ = .term'.n'$ + .baseTerm'.bit'$
                endif
            endfor
        endif
    endfor
endproc

# ============================================================================
# @emlParseFormula
# Parse R-style formula: "y ~ A * B + (1 + A | Subject) + (1 | Item)"
#
# Output:
#   .response$          — response variable name
#   .hasIntercept       — 1 if fixed intercept included
#   .nFixed             — number of fixed-effect terms (after expansion)
#   .fixedTerm'.i'$     — each fixed effect term
#   .nRandom            — number of random-effect groups
#   .reNTerms'.j'       — number of terms in RE group j
#   .reTerm'.j'_'.k'$   — k-th term in RE group j
#   .reGroup'.j'$       — grouping variable for RE group j
#   .reCorrelated'.j'   — 1 if correlated, 0 if uncorrelated (||)
#   .reNested'.j'       — 1 if nested via /
#   .nCoerce            — number of type coercions
#   .coerceVar'.i'$     — variable name
#   .coerceType'.i'$    — "factor" or "numeric"
#   .error$
# ============================================================================
procedure emlParseFormula: .formula$
    .error$ = ""
    .hasIntercept = 1
    .nFixed = 0
    .nRandom = 0
    .nCoerce = 0

    # ---- Extract type coercions: factor(...), numeric(...) ----
    .work$ = .formula$
    .scanning = 1
    while .scanning
        .fpos = index (.work$, "factor(")
        .npos = index (.work$, "numeric(")
        if .fpos = 0 and .npos = 0
            .scanning = 0
        else
            if .fpos > 0 and (.npos = 0 or .fpos < .npos)
                .coerceStart = .fpos
                .coerceType$ = "factor"
                .kwLen = 7
            else
                .coerceStart = .npos
                .coerceType$ = "numeric"
                .kwLen = 8
            endif
            # Find matching )
            .closePos = index (mid$ (.work$, .coerceStart + .kwLen,
                ... length (.work$) - .coerceStart - .kwLen + 1), ")")
            if .closePos = 0
                .error$ = "Unmatched parenthesis in " + .coerceType$ + "()"
                goto END_PARSE
            endif
            .closePos = .coerceStart + .kwLen + .closePos - 1
            .innerVar$ = mid$ (.work$, .coerceStart + .kwLen,
                ... .closePos - .coerceStart - .kwLen)
            @emlTrimWhitespace: .innerVar$
            .nCoerce = .nCoerce + 1
            .coerceVar'.nCoerce'$ = emlTrimWhitespace.result$
            .coerceType'.nCoerce'$ = .coerceType$
            # Replace factor(X) with X in the formula
            .before$ = left$ (.work$, .coerceStart - 1)
            .after$ = mid$ (.work$, .closePos + 1,
                ... length (.work$) - .closePos)
            .work$ = .before$ + emlTrimWhitespace.result$ + .after$
        endif
    endwhile

    # ---- Split on ~ ----
    .tildePos = index (.work$, "~")
    if .tildePos = 0
        .error$ = "Formula must contain ~"
        goto END_PARSE
    endif
    @emlTrimWhitespace: left$ (.work$, .tildePos - 1)
    .response$ = emlTrimWhitespace.result$
    @emlTrimWhitespace: mid$ (.work$, .tildePos + 1,
        ... length (.work$) - .tildePos)
    .predictors$ = emlTrimWhitespace.result$

    # ---- Extract random effects: balanced ( ) containing | ----
    .nRandom = 0
    .fixedStr$ = ""
    .pos = 1
    .pLen = length (.predictors$)
    while .pos <= .pLen
        .ch$ = mid$ (.predictors$, .pos, 1)
        if .ch$ = "("
            # Find matching close paren
            .depth = 1
            .start = .pos
            .pos = .pos + 1
            while .pos <= .pLen and .depth > 0
                .ch2$ = mid$ (.predictors$, .pos, 1)
                if .ch2$ = "("
                    .depth = .depth + 1
                elsif .ch2$ = ")"
                    .depth = .depth - 1
                endif
                .pos = .pos + 1
            endwhile
            .groupContent$ = mid$ (.predictors$, .start + 1,
                ... .pos - .start - 2)
            # Check if this contains | (random effect)
            .barPos = index (.groupContent$, "|")
            if .barPos > 0
                .nRandom = .nRandom + 1
                .j = .nRandom
                # Check for || (uncorrelated)
                .doubleBar = index (.groupContent$, "||")
                if .doubleBar > 0
                    .reCorrelated'.j' = 0
                    @emlTrimWhitespace: left$ (.groupContent$, .doubleBar - 1)
                    .reLHS$ = emlTrimWhitespace.result$
                    @emlTrimWhitespace: mid$ (.groupContent$, .doubleBar + 2,
                        ... length (.groupContent$) - .doubleBar - 1)
                    .reRHS$ = emlTrimWhitespace.result$
                else
                    .reCorrelated'.j' = 1
                    @emlTrimWhitespace: left$ (.groupContent$, .barPos - 1)
                    .reLHS$ = emlTrimWhitespace.result$
                    @emlTrimWhitespace: mid$ (.groupContent$, .barPos + 1,
                        ... length (.groupContent$) - .barPos)
                    .reRHS$ = emlTrimWhitespace.result$
                endif

                # Check for nested grouping: g1/g2
                .slashPos = index (.reRHS$, "/")
                if .slashPos > 0
                    .reNested'.j' = 1
                    # g1/g2 expands to (terms|g1) + (terms|g1:g2)
                    @emlTrimWhitespace: left$ (.reRHS$, .slashPos - 1)
                    .g1$ = emlTrimWhitespace.result$
                    @emlTrimWhitespace: mid$ (.reRHS$, .slashPos + 1,
                        ... length (.reRHS$) - .slashPos)
                    .g2$ = emlTrimWhitespace.result$
                    .reGroup'.j'$ = .g1$
                    # Parse terms for this group
                    @emlSplitTerms: .reLHS$, "+"
                    .reNTerms'.j' = emlSplitTerms.n
                    for .k from 1 to emlSplitTerms.n
                        .reTerm'.j'_'.k'$ = emlSplitTerms.term'.k'$
                    endfor
                    # Add the nested group as a separate RE term
                    .nRandom = .nRandom + 1
                    .j2 = .nRandom
                    .reCorrelated'.j2' = .reCorrelated'.j'
                    .reNested'.j2' = 0
                    .reGroup'.j2'$ = .g1$ + ":" + .g2$
                    .reNTerms'.j2' = .reNTerms'.j'
                    for .k from 1 to .reNTerms'.j'
                        .reTerm'.j2'_'.k'$ = .reTerm'.j'_'.k'$
                    endfor
                else
                    .reNested'.j' = 0
                    .reGroup'.j'$ = .reRHS$
                    # Parse RE terms
                    @emlSplitTerms: .reLHS$, "+"
                    .reNTerms'.j' = emlSplitTerms.n
                    for .k from 1 to emlSplitTerms.n
                        .reTerm'.j'_'.k'$ = emlSplitTerms.term'.k'$
                    endfor
                endif

                # For uncorrelated (||): if implicit intercept, add it
                if .reCorrelated'.j' = 0
                    # || implies intercept + slopes, all uncorrelated
                    # Check if 1 is already in terms
                    .hasOne = 0
                    for .k from 1 to .reNTerms'.j'
                        if .reTerm'.j'_'.k'$ = "1"
                            .hasOne = 1
                        endif
                    endfor
                    if .hasOne = 0
                        # Add implicit intercept
                        .oldN = .reNTerms'.j'
                        # Reverse shift (oldN..1) to open slot 1 for the
                        # implicit intercept. Praat for-loops only increment,
                        # so walk an ascending counter and mirror the index.
                        for .kRev from 1 to .oldN
                            .k = .oldN - .kRev + 1
                            .kp = .k + 1
                            .reTerm'.j'_'.kp'$ = .reTerm'.j'_'.k'$
                        endfor
                        .reTerm'.j'_1$ = "1"
                        .reNTerms'.j' = .oldN + 1
                    endif
                endif
            else
                # Parenthesized group without | — I() or other
                .fixedStr$ = .fixedStr$ + "(" + .groupContent$ + ")"
            endif
        else
            .fixedStr$ = .fixedStr$ + .ch$
            .pos = .pos + 1
        endif
    endwhile

    # ---- Parse fixed effects ----
    @emlTrimWhitespace: .fixedStr$
    .fixedStr$ = emlTrimWhitespace.result$

    # Handle leading/trailing + from RE removal
    .fixedStr$ = replace_regex$ (.fixedStr$, "^\++", "", 0)
    .fixedStr$ = replace_regex$ (.fixedStr$, "\++$", "", 0)
    .fixedStr$ = replace_regex$ (.fixedStr$, "\+\+", "+", 0)
    @emlTrimWhitespace: .fixedStr$
    .fixedStr$ = emlTrimWhitespace.result$

    # Split on + and - (track sign for removal)
    .nFixed = 0
    .nRemoved = 0
    if .fixedStr$ <> ""
        # Normalize: replace " - " with " + -" so split on + captures removals
        # Must respect parenthesized groups
        .normStr$ = ""
        .depth = 0
        for .ci from 1 to length (.fixedStr$)
            .cc$ = mid$ (.fixedStr$, .ci, 1)
            if .cc$ = "("
                .depth = .depth + 1
            elsif .cc$ = ")"
                .depth = .depth - 1
            endif
            if .cc$ = "-" and .depth = 0 and .ci > 1
                .normStr$ = .normStr$ + "+-"
            else
                .normStr$ = .normStr$ + .cc$
            endif
        endfor
        .fixedStr$ = .normStr$
        # Tokenize: split on + keeping - as removal markers
        @emlSplitTerms: .fixedStr$, "+"
        .nRawTerms = emlSplitTerms.n
        for .t from 1 to .nRawTerms
            .savedRawTerm'.t'$ = emlSplitTerms.term'.t'$
        endfor
        for .t from 1 to .nRawTerms
            .rawTerm$ = .savedRawTerm'.t'$
            # Check for removal (leading -)
            .isRemoval = 0
            if left$ (.rawTerm$, 1) = "-"
                .isRemoval = 1
                @emlTrimWhitespace: mid$ (.rawTerm$, 2, length (.rawTerm$) - 1)
                .rawTerm$ = emlTrimWhitespace.result$
            endif

            # Check for intercept control
            if .rawTerm$ = "0"
                .hasIntercept = 0
            elsif .rawTerm$ = "1"
                if .isRemoval
                    .hasIntercept = 0
                endif
                # Explicit 1 doesn't add a term; intercept is implicit
            else
                # Check for * crossing
                .hasStar = index (.rawTerm$, "*")
                # Check for ^ degree
                .hasCaret = index (.rawTerm$, "^")
                if .hasStar > 0
                    @emlExpandCrossing: .rawTerm$
                    for .e from 1 to emlExpandCrossing.n
                        if .isRemoval
                            .nRemoved = .nRemoved + 1
                            .removedTerm'.nRemoved'$ = emlExpandCrossing.term'.e'$
                        else
                            .nFixed = .nFixed + 1
                            .fixedTerm'.nFixed'$ = emlExpandCrossing.term'.e'$
                        endif
                    endfor
                elsif .hasCaret > 0
                    # Parse "(...) ^ n" or "term ^ n"
                    # Find the degree
                    @emlTrimWhitespace: mid$ (.rawTerm$, .hasCaret + 1,
                        ... length (.rawTerm$) - .hasCaret)
                    .degree = number (emlTrimWhitespace.result$)
                    @emlTrimWhitespace: left$ (.rawTerm$, .hasCaret - 1)
                    .baseExpr$ = emlTrimWhitespace.result$
                    # Strip outer parens if present
                    if left$ (.baseExpr$, 1) = "("
                        .baseExpr$ = mid$ (.baseExpr$, 2,
                            ... length (.baseExpr$) - 2)
                    endif
                    # Split base terms
                    @emlSplitTerms: .baseExpr$, "+"
                    .nBaseDeg = emlSplitTerms.n
                    for .b from 1 to .nBaseDeg
                        emlExpandDegree.baseTerm'.b'$ = emlSplitTerms.term'.b'$
                    endfor
                    @emlExpandDegree: .nBaseDeg, .degree
                    for .e from 1 to emlExpandDegree.n
                        if .isRemoval
                            .nRemoved = .nRemoved + 1
                            .removedTerm'.nRemoved'$ = emlExpandDegree.term'.e'$
                        else
                            .nFixed = .nFixed + 1
                            .fixedTerm'.nFixed'$ = emlExpandDegree.term'.e'$
                        endif
                    endfor
                else
                    # Simple term or interaction (A:B)
                    if .isRemoval
                        .nRemoved = .nRemoved + 1
                        .removedTerm'.nRemoved'$ = .rawTerm$
                    else
                        .nFixed = .nFixed + 1
                        .fixedTerm'.nFixed'$ = .rawTerm$
                    endif
                endif
            endif
        endfor
    endif

    # Apply removals
    if .nRemoved > 0
        .nKept = 0
        for .i from 1 to .nFixed
            .shouldRemove = 0
            for .r from 1 to .nRemoved
                if .fixedTerm'.i'$ = .removedTerm'.r'$
                    .shouldRemove = 1
                endif
            endfor
            if .shouldRemove = 0
                .nKept = .nKept + 1
                .keptTerm'.nKept'$ = .fixedTerm'.i'$
            endif
        endfor
        .nFixed = .nKept
        for .i from 1 to .nFixed
            .fixedTerm'.i'$ = .keptTerm'.i'$
        endfor
    endif

    # Deduplicate fixed terms
    .nDeduped = 0
    for .i from 1 to .nFixed
        .isDup = 0
        for .j from 1 to .nDeduped
            if .fixedTerm'.i'$ = .dedupTerm'.j'$
                .isDup = 1
            endif
        endfor
        if .isDup = 0
            .nDeduped = .nDeduped + 1
            .dedupTerm'.nDeduped'$ = .fixedTerm'.i'$
        endif
    endfor
    .nFixed = .nDeduped
    for .i from 1 to .nFixed
        .fixedTerm'.i'$ = .dedupTerm'.i'$
    endfor

    label END_PARSE
endproc

# ============================================================================
# @emlContrastMatrix
# Generate contrast coding matrix for a factor with k levels.
# Input: .nLevels, .coding$ ("treatment", "sum", "helmert", "poly")
# Output: .c## (nLevels × nLevels-1), .nCols
# ============================================================================
procedure emlContrastMatrix: .nLevels, .coding$
    .nCols = .nLevels - 1
    .c## = zero## (.nLevels, .nCols)

    if .coding$ = "treatment"
        # Treatment (dummy) coding: reference = first level
        for .i from 2 to .nLevels
            .c## [.i, .i - 1] = 1
        endfor

    elsif .coding$ = "sum"
        # Sum (deviation) coding: last level = -(sum of others)
        for .i from 1 to .nCols
            .c## [.i, .i] = 1
        endfor
        for .j from 1 to .nCols
            .c## [.nLevels, .j] = -1
        endfor

    elsif .coding$ = "helmert"
        # Helmert coding in R's INTEGER form (contr.helmert): column j has
        # -1 in rows 1..j and +j in row j+1. The earlier -1/j : 1 scaling
        # produced the same contrast direction but rescaled every Helmert
        # coefficient by a factor of j, so fitted coefficients would not match
        # lme4. Integer form makes them match exactly.
        for .j from 1 to .nCols
            for .i from 1 to .j
                .c## [.i, .j] = -1
            endfor
            .c## [.j + 1, .j] = .j
        endfor

    elsif .coding$ = "poly"
        # Orthogonal polynomial coding
        # Use Gram-Schmidt on {1, x, x^2, ...} where x = 1..k
        .raw## = zero## (.nLevels, .nLevels)
        for .i from 1 to .nLevels
            .raw## [.i, 1] = 1
            for .j from 2 to .nLevels
                .raw## [.i, .j] = .i ^ (.j - 1)
            endfor
        endfor
        # Gram-Schmidt orthogonalization
        .q## = zero## (.nLevels, .nLevels)
        for .j from 1 to .nLevels
            # Copy column j
            for .i from 1 to .nLevels
                .q## [.i, .j] = .raw## [.i, .j]
            endfor
            # Subtract projections of previous columns
            for .k from 1 to .j - 1
                .dot1 = 0
                .dot2 = 0
                for .i from 1 to .nLevels
                    .dot1 = .dot1 + .q## [.i, .j] * .q## [.i, .k]
                    .dot2 = .dot2 + .q## [.i, .k] * .q## [.i, .k]
                endfor
                .proj = .dot1 / .dot2
                for .i from 1 to .nLevels
                    .q## [.i, .j] = .q## [.i, .j] - .proj * .q## [.i, .k]
                endfor
            endfor
            # Normalize
            .norm = 0
            for .i from 1 to .nLevels
                .norm = .norm + .q## [.i, .j] * .q## [.i, .j]
            endfor
            .norm = sqrt (.norm)
            if .norm > 1e-15
                for .i from 1 to .nLevels
                    .q## [.i, .j] = .q## [.i, .j] / .norm
                endfor
            endif
        endfor
        # Extract columns 2..nLevels (skip intercept column)
        for .i from 1 to .nLevels
            for .j from 1 to .nCols
                .c## [.i, .j] = .q## [.i, .j + 1]
            endfor
        endfor
    endif
endproc

# ============================================================================
# UTILITY: @emlGetUniqueLevels
# Extract unique levels from a Table column. Determines if column is
# categorical or numeric. Sorts levels alphabetically.
# Input: .tableId, .colName$
# Output: .nLevels, .level'.i'$, .isCategorical
# ============================================================================
procedure emlGetUniqueLevels: .tableId, .colName$
    selectObject: .tableId
    .nRows = Get number of rows
    .nLevels = 0
    .isCategorical = 0

    # Check if column is numeric
    .allNumeric = 1
    for .row from 1 to .nRows
        selectObject: .tableId
        .val$ = Get value: .row, .colName$
        .num = number (.val$)
        .isUndef = (.num = undefined)
        if .isUndef and .val$ <> "--undefined--"
            .allNumeric = 0
        endif
    endfor

    # Check for forced coercion via the formula parser output
    # (Caller is responsible for checking .coerce flags)
    if .allNumeric = 0
        .isCategorical = 1
    endif

    # Collect unique levels
    for .row from 1 to .nRows
        selectObject: .tableId
        .val$ = Get value: .row, .colName$
        .found = 0
        for .k from 1 to .nLevels
            if .level'.k'$ = .val$
                .found = 1
            endif
        endfor
        if .found = 0
            .nLevels = .nLevels + 1
            .level'.nLevels'$ = .val$
        endif
    endfor

    # Sort levels alphabetically (bubble sort — levels are typically < 20)
    for .i from 1 to .nLevels - 1
        for .j from 1 to .nLevels - .i
            .jp = .j + 1
            if .level'.j'$ > .level'.jp'$
                .tmp$ = .level'.j'$
                .level'.j'$ = .level'.jp'$
                .level'.jp'$ = .tmp$
            endif
        endfor
    endfor
endproc

# ============================================================================
# @emlModelMatrix
# Build fixed-effects design matrix X from a Table and parsed formula.
# Must call @emlParseFormula first.
#
# Input: .tableId, .contrastCoding$ ("treatment"/"sum"/"helmert"/"poly")
# Reads: emlParseFormula.* (formula parse results)
# Output: .x## (n × p), .p (number of columns), .n (number of rows)
#         .colName'.i'$ — column label for each X column
# ============================================================================
procedure emlModelMatrix: .tableId, .contrastCoding$
    selectObject: .tableId
    .n = Get number of rows

    # Determine which columns are categorical (with coercion)
    .nTermVars = 0
    for .t from 1 to emlParseFormula.nFixed
        .term$ = emlParseFormula.fixedTerm'.t'$
        # Split interaction terms on :
        @emlSplitTerms: .term$, ":"
        for .s from 1 to emlSplitTerms.n
            .varName$ = emlSplitTerms.term'.s'$
            # Check if already registered
            .found = 0
            for .v from 1 to .nTermVars
                if .termVar'.v'$ = .varName$
                    .found = 1
                endif
            endfor
            if .found = 0
                .nTermVars = .nTermVars + 1
                .termVar'.nTermVars'$ = .varName$
                # Check coercion
                .forceFactor = 0
                .forceNumeric = 0
                for .c from 1 to emlParseFormula.nCoerce
                    if emlParseFormula.coerceVar'.c'$ = .varName$
                        if emlParseFormula.coerceType'.c'$ = "factor"
                            .forceFactor = 1
                        elsif emlParseFormula.coerceType'.c'$ = "numeric"
                            .forceNumeric = 1
                        endif
                    endif
                endfor
                @emlGetUniqueLevels: .tableId, .varName$
                .varNLevels'.nTermVars' = emlGetUniqueLevels.nLevels
                if .forceNumeric
                    .varIsCat'.nTermVars' = 0
                elsif .forceFactor or emlGetUniqueLevels.isCategorical
                    .varIsCat'.nTermVars' = 1
                else
                    .varIsCat'.nTermVars' = 0
                endif
                # Store levels
                for .lv from 1 to emlGetUniqueLevels.nLevels
                    .varLevel'.nTermVars'_'.lv'$ = emlGetUniqueLevels.level'.lv'$
                endfor
                # Build contrast matrix if categorical
                if .varIsCat'.nTermVars'
                    @emlContrastMatrix: .varNLevels'.nTermVars', .contrastCoding$
                    .varContrast'.nTermVars'## = emlContrastMatrix.c##
                    .varNCols'.nTermVars' = emlContrastMatrix.nCols
                else
                    .varNCols'.nTermVars' = 1
                endif
            endif
        endfor
    endfor

    # Count total columns (intercept + each term)
    .p = 0
    if emlParseFormula.hasIntercept
        .p = 1
    endif

    # For each fixed term, compute number of columns it contributes
    for .t from 1 to emlParseFormula.nFixed
        .term$ = emlParseFormula.fixedTerm'.t'$
        @emlSplitTerms: .term$, ":"
        .termNCols = 1
        for .s from 1 to emlSplitTerms.n
            .varName$ = emlSplitTerms.term'.s'$
            # Find var index
            for .v from 1 to .nTermVars
                if .termVar'.v'$ = .varName$
                    .termNCols = .termNCols * .varNCols'.v'
                endif
            endfor
        endfor
        .termStartCol'.t' = .p + 1
        .termNCols'.t' = .termNCols
        .p = .p + .termNCols
    endfor

    # Build X matrix
    .x## = zero## (.n, .p)
    .colIdx = 0

    # Intercept column
    if emlParseFormula.hasIntercept
        .colIdx = .colIdx + 1
        .colName'.colIdx'$ = "(Intercept)"
        for .row from 1 to .n
            .x## [.row, .colIdx] = 1
        endfor
    endif

    # Each fixed term
    for .t from 1 to emlParseFormula.nFixed
        .term$ = emlParseFormula.fixedTerm'.t'$
        @emlSplitTerms: .term$, ":"
        .interOrder = emlSplitTerms.n
        # Store interaction components
        for .s from 1 to .interOrder
            .interVar'.s'$ = emlSplitTerms.term'.s'$
        endfor

        if .interOrder = 1
            # Simple main effect
            .varName$ = .interVar1$
            # Find var index
            .vi = 0
            for .v from 1 to .nTermVars
                if .termVar'.v'$ = .varName$
                    .vi = .v
                endif
            endfor
            if .varIsCat'.vi'
                # Categorical: add contrast-coded columns
                for .cc from 1 to .varNCols'.vi'
                    .colIdx = .colIdx + 1
                    .refLevel$ = .varLevel'.vi'_1$
                    .ccPlus = .cc + 1
                    .cmpLevel$ = .varLevel'.vi'_'.ccPlus'$
                    .colName'.colIdx'$ = .varName$ + .cmpLevel$
                    for .row from 1 to .n
                        selectObject: .tableId
                        .rv$ = Get value: .row, .varName$
                        # Find level index
                        .lvIdx = 0
                        for .lv from 1 to .varNLevels'.vi'
                            if .varLevel'.vi'_'.lv'$ = .rv$
                                .lvIdx = .lv
                            endif
                        endfor
                        .x## [.row, .colIdx] = .varContrast'.vi'## [.lvIdx, .cc]
                    endfor
                endfor
            else
                # Continuous: single column
                .colIdx = .colIdx + 1
                .colName'.colIdx'$ = .varName$
                for .row from 1 to .n
                    selectObject: .tableId
                    .rv$ = Get value: .row, .varName$
                    .x## [.row, .colIdx] = number (.rv$)
                endfor
            endif
        else
            # Interaction: compute Kronecker product of component columns
            # For now handle 2-way and 3-way interactions
            # General approach: build each component's columns, then
            # compute all combinations of products

            # Collect component column blocks
            .totalInterCols = 1
            for .s from 1 to .interOrder
                .ivarName$ = .interVar'.s'$
                .ivi = 0
                for .v from 1 to .nTermVars
                    if .termVar'.v'$ = .ivarName$
                        .ivi = .v
                    endif
                endfor
                .interVarIdx'.s' = .ivi
                .interNCols'.s' = .varNCols'.ivi'
                .totalInterCols = .totalInterCols * .varNCols'.ivi'
            endfor

            # Generate all column combinations
            # Use base-decomposition of column index
            for .ci from 1 to .totalInterCols
                .colIdx = .colIdx + 1
                # Decompose ci-1 into component column indices
                .remaining = .ci - 1
                .colLabel$ = ""
                # Mixed-radix decompose from the last component to the first
                # (interOrder..1). Praat for-loops only increment, so walk an
                # ascending counter and mirror the index — the sequential
                # .remaining update requires this exact descending order.
                for .sRev from 1 to .interOrder
                    .s = .interOrder - .sRev + 1
                    .ivi = .interVarIdx'.s'
                    .compCol'.s' = (.remaining mod .interNCols'.s') + 1
                    .remaining = floor (.remaining / .interNCols'.s')
                    .ivarName$ = .interVar'.s'$
                    if .varIsCat'.ivi'
                        .ccP = .compCol'.s' + 1
                        .lvName$ = .varLevel'.ivi'_'.ccP'$
                        if .colLabel$ = ""
                            .colLabel$ = .ivarName$ + .lvName$
                        else
                            .colLabel$ = .ivarName$ + .lvName$ + ":" + .colLabel$
                        endif
                    else
                        if .colLabel$ = ""
                            .colLabel$ = .ivarName$
                        else
                            .colLabel$ = .ivarName$ + ":" + .colLabel$
                        endif
                    endif
                endfor
                .colName'.colIdx'$ = .colLabel$

                # Compute column values (product of components)
                for .row from 1 to .n
                    .val = 1
                    for .s from 1 to .interOrder
                        .ivi = .interVarIdx'.s'
                        .ivarName$ = .interVar'.s'$
                        if .varIsCat'.ivi'
                            selectObject: .tableId
                            .rv$ = Get value: .row, .ivarName$
                            .lvIdx = 0
                            for .lv from 1 to .varNLevels'.ivi'
                                if .varLevel'.ivi'_'.lv'$ = .rv$
                                    .lvIdx = .lv
                                endif
                            endfor
                            .ccIdx = .compCol'.s'
                            .val = .val * .varContrast'.ivi'## [.lvIdx, .ccIdx]
                        else
                            selectObject: .tableId
                            .rv$ = Get value: .row, .ivarName$
                            .val = .val * number (.rv$)
                        endif
                    endfor
                    .x## [.row, .colIdx] = .val
                endfor
            endfor
        endif
    endfor
endproc

# ============================================================================
# @emlRandomEffectsZ
# Build random-effects design matrix Z and Lambda template.
# Must call @emlParseFormula first.
#
# Input: .tableId, .contrastCoding$
# Reads: emlParseFormula.* (formula parse results)
# Output:
#   .z## (n × q)           — random effects design matrix
#   .q                     — total RE columns
#   .nTerms                — number of RE groups
#   .thetaSize             — total theta parameters
#   .thetaLower#           — lower bounds for theta
#   .termStart'.j'         — starting column of RE group j in Z
#   .termSize'.j'          — number of columns for RE group j
#   .termNLevels'.j'       — number of group levels
#   .termNEffects'.j'      — effects per level (1 for intercept only)
#   .termCorrelated'.j'    — correlation flag
#   .termThetaStart'.j'    — starting index in theta vector
#   .termThetaSize'.j'     — number of theta params for this term
#   .termLevel'.j'_'.k'$   — level labels
# ============================================================================
procedure emlRandomEffectsZ: .tableId, .contrastCoding$
    selectObject: .tableId
    .n = Get number of rows
    .nTerms = emlParseFormula.nRandom

    # First pass: compute sizes
    .q = 0
    .thetaSize = 0
    for .j from 1 to .nTerms
        .groupVar$ = emlParseFormula.reGroup'.j'$

        # Handle interaction grouping (g1:g2)
        .colonPos = index (.groupVar$, ":")
        if .colonPos > 0
            # Create interaction grouping column
            @emlTrimWhitespace: left$ (.groupVar$, .colonPos - 1)
            .g1$ = emlTrimWhitespace.result$
            @emlTrimWhitespace: mid$ (.groupVar$, .colonPos + 1,
                ... length (.groupVar$) - .colonPos)
            .g2$ = emlTrimWhitespace.result$
            # Get unique combinations
            .nLevels = 0
            for .row from 1 to .n
                selectObject: .tableId
                .v1$ = Get value: .row, .g1$
                .v2$ = Get value: .row, .g2$
                .combo$ = .v1$ + ":" + .v2$
                .found = 0
                for .k from 1 to .nLevels
                    if .termLevel'.j'_'.k'$ = .combo$
                        .found = 1
                    endif
                endfor
                if .found = 0
                    .nLevels = .nLevels + 1
                    .termLevel'.j'_'.nLevels'$ = .combo$
                endif
            endfor
        else
            # Simple grouping variable
            @emlGetUniqueLevels: .tableId, .groupVar$
            .nLevels = emlGetUniqueLevels.nLevels
            for .k from 1 to .nLevels
                .termLevel'.j'_'.k'$ = emlGetUniqueLevels.level'.k'$
            endfor
        endif

        .termNLevels'.j' = .nLevels

        # Count effects per level (intercept + slopes)
        .nEffects = 0
        for .k from 1 to emlParseFormula.reNTerms'.j'
            .reTerm$ = emlParseFormula.reTerm'.j'_'.k'$
            if .reTerm$ = "1" or .reTerm$ = "0"
                if .reTerm$ = "1"
                    .nEffects = .nEffects + 1
                endif
            else
                # Check if variable is categorical
                .found = 0
                .isCat = 0
                .nCatCols = 1
                for .v from 1 to emlModelMatrix.nTermVars
                    if emlModelMatrix.termVar'.v'$ = .reTerm$
                        .found = 1
                        .isCat = emlModelMatrix.varIsCat'.v'
                        .nCatCols = emlModelMatrix.varNCols'.v'
                    endif
                endfor
                if .found = 0
                    # Variable not in fixed effects — check directly
                    @emlGetUniqueLevels: .tableId, .reTerm$
                    .isCat = emlGetUniqueLevels.isCategorical
                    if .isCat
                        .nCatCols = emlGetUniqueLevels.nLevels - 1
                    endif
                endif
                if .isCat
                    .nEffects = .nEffects + .nCatCols
                else
                    .nEffects = .nEffects + 1
                endif
            endif
        endfor
        .termNEffects'.j' = .nEffects
        .termCorrelated'.j' = emlParseFormula.reCorrelated'.j'
        .termStart'.j' = .q + 1
        .termSize'.j' = .nLevels * .nEffects
        .q = .q + .termSize'.j'

        # Theta parameters
        .termThetaStart'.j' = .thetaSize + 1
        if .termCorrelated'.j'
            # Lower-triangular: m*(m+1)/2 parameters
            .termThetaSize'.j' = .nEffects * (.nEffects + 1) / 2
        else
            # Diagonal only: m parameters
            .termThetaSize'.j' = .nEffects
        endif
        .thetaSize = .thetaSize + .termThetaSize'.j'
    endfor

    # Build theta lower bounds
    .thetaLower# = zero# (.thetaSize)
    for .j from 1 to .nTerms
        .tStart = .termThetaStart'.j'
        .m = .termNEffects'.j'
        if .termCorrelated'.j'
            # Diagonal elements ≥ 0, off-diagonal unbounded
            .idx = 0
            for .row from 1 to .m
                for .col from 1 to .row
                    .idx = .idx + 1
                    if .row = .col
                        .thetaLower# [.tStart + .idx - 1] = 0
                    else
                        .thetaLower# [.tStart + .idx - 1] = -1e30
                    endif
                endfor
            endfor
        else
            # All diagonal, all ≥ 0
            for .idx from 1 to .termThetaSize'.j'
                .thetaLower# [.tStart + .idx - 1] = 0
            endfor
        endif
    endfor

    # Build Z matrix
    .z## = zero## (.n, .q)

    for .j from 1 to .nTerms
        .groupVar$ = emlParseFormula.reGroup'.j'$
        .zStart = .termStart'.j'
        .nEffects = .termNEffects'.j'
        .nLevels = .termNLevels'.j'

        for .row from 1 to .n
            selectObject: .tableId
            # Get group level for this row
            .colonPos = index (.groupVar$, ":")
            if .colonPos > 0
                @emlTrimWhitespace: left$ (.groupVar$, .colonPos - 1)
                .g1$ = emlTrimWhitespace.result$
                @emlTrimWhitespace: mid$ (.groupVar$, .colonPos + 1,
                    ... length (.groupVar$) - .colonPos)
                .g2$ = emlTrimWhitespace.result$
                selectObject: .tableId
                .v1$ = Get value: .row, .g1$
                .v2$ = Get value: .row, .g2$
                .rowLevel$ = .v1$ + ":" + .v2$
            else
                selectObject: .tableId
                .rowLevel$ = Get value: .row, .groupVar$
            endif

            # Find level index
            .lvIdx = 0
            for .k from 1 to .nLevels
                if .termLevel'.j'_'.k'$ = .rowLevel$
                    .lvIdx = .k
                endif
            endfor

            # Fill Z columns for this level
            .effIdx = 0
            for .k from 1 to emlParseFormula.reNTerms'.j'
                .reTerm$ = emlParseFormula.reTerm'.j'_'.k'$
                if .reTerm$ = "1"
                    .effIdx = .effIdx + 1
                    .zCol = .zStart + (.lvIdx - 1) * .nEffects + .effIdx - 1
                    .z## [.row, .zCol] = 1
                elsif .reTerm$ <> "0"
                    # Get the value(s) for this variable
                    # Check if categorical
                    .isCat = 0
                    .nCC = 1
                    for .v from 1 to emlModelMatrix.nTermVars
                        if emlModelMatrix.termVar'.v'$ = .reTerm$
                            .isCat = emlModelMatrix.varIsCat'.v'
                            .nCC = emlModelMatrix.varNCols'.v'
                        endif
                    endfor
                    if .isCat
                        for .cc from 1 to .nCC
                            .effIdx = .effIdx + 1
                            selectObject: .tableId
                            .rv$ = Get value: .row, .reTerm$
                            .lvI = 0
                            for .v from 1 to emlModelMatrix.nTermVars
                                if emlModelMatrix.termVar'.v'$ = .reTerm$
                                    for .lv from 1 to emlModelMatrix.varNLevels'.v'
                                        if emlModelMatrix.varLevel'.v'_'.lv'$ = .rv$
                                            .lvI = .lv
                                        endif
                                    endfor
                                    .vi = .v
                                endif
                            endfor
                            .zCol = .zStart + (.lvIdx - 1) * .nEffects + .effIdx - 1
                            .z## [.row, .zCol] = emlModelMatrix.varContrast'.vi'## [.lvI, .cc]
                        endfor
                    else
                        .effIdx = .effIdx + 1
                        selectObject: .tableId
                        .rv$ = Get value: .row, .reTerm$
                        .zCol = .zStart + (.lvIdx - 1) * .nEffects + .effIdx - 1
                        .z## [.row, .zCol] = number (.rv$)
                    endif
                endif
            endfor
        endfor
    endfor
endproc

# ============================================================================
# @emlConstructLambda
# Build block-diagonal Lambda from theta vector.
# Reads: emlRandomEffectsZ.* for structure
# Input: .theta#
# Output: .lambda## (q × q block-diagonal)
# ============================================================================
procedure emlConstructLambda: .theta#
    .q = emlRandomEffectsZ.q
    .lambda## = zero## (.q, .q)

    for .j from 1 to emlRandomEffectsZ.nTerms
        .tStart = emlRandomEffectsZ.termThetaStart'.j'
        .m = emlRandomEffectsZ.termNEffects'.j'
        .nLevels = emlRandomEffectsZ.termNLevels'.j'
        .zStart = emlRandomEffectsZ.termStart'.j'
        .correlated = emlRandomEffectsZ.termCorrelated'.j'

        # Build m × m template from theta
        .tmpl## = zero## (.m, .m)
        if .correlated
            .idx = 0
            for .row from 1 to .m
                for .col from 1 to .row
                    .idx = .idx + 1
                    .tmpl## [.row, .col] = .theta# [.tStart + .idx - 1]
                endfor
            endfor
        else
            for .diag from 1 to .m
                .tmpl## [.diag, .diag] = .theta# [.tStart + .diag - 1]
            endfor
        endif

        # Replicate template for each group level
        for .lv from 1 to .nLevels
            .blockStart = .zStart + (.lv - 1) * .m
            for .row from 1 to .m
                for .col from 1 to .m
                    .lambda## [.blockStart + .row - 1,
                        ... .blockStart + .col - 1] = .tmpl## [.row, .col]
                endfor
            endfor
        endfor
    endfor
endproc

# ============================================================================
# @emlProfiledDeviance
# Profiled REML/ML deviance — objective for BOBYQA.
# Follows Bates et al. (2015) §2.
#
# Protocol: Called as @emlProfiledDeviance: theta#
#           Sets .value (the deviance)
# Reads shared state from emlLMM.* namespace
# ============================================================================
procedure emlProfiledDeviance: .theta#
    .n = emlLMM.nObs
    .p = emlLMM.nFixedCols
    .q = emlLMM.nRandomCols

    # Step 1: Lambda from theta
    @emlConstructLambda: .theta#

    # Step 2: ZLambda = Z * Lambda
    .zl## = mul## (emlLMM.z##, emlConstructLambda.lambda##)

    # Step 3: A = ZLambda' ZLambda + I
    .zlt## = transpose## (.zl##)
    .a## = mul## (.zlt##, .zl##)
    for .i from 1 to .q
        .a## [.i, .i] = .a## [.i, .i] + 1
    endfor

    # Step 4: L_theta = chol(A)
    @emlCholesky: .a##
    if emlCholesky.error$ <> ""
        # Non-PD — return large deviance
        .value = 1e30
        goto END_PROFDEV
    endif
    .lTheta## = emlCholesky.l##

    # Step 5: cu = L_theta^{-1} * ZLambda' * y (forward solve via native solve#)
    .zty# = mul# (.zlt##, emlLMM.y#)
    .cu# = solve# (.lTheta##, .zty#)

    # Step 6: RZX = L_theta^{-1} * ZLambda' * X (forward solve multi via native solve##)
    .ztx## = mul## (.zlt##, emlLMM.x##)
    .rzx## = solve## (.lTheta##, .ztx##)

    # Step 7: downdated X'X = X'X - RZX'RZX
    .xtx## = mul## (transpose## (emlLMM.x##), emlLMM.x##)
    .rzxt## = transpose## (.rzx##)
    .dd## = .xtx## - mul## (.rzxt##, .rzx##)

    # Step 8: RX = chol(downdated)
    @emlCholesky: .dd##
    if emlCholesky.error$ <> ""
        .value = 1e30
        goto END_PROFDEV
    endif
    .rx## = emlCholesky.l##

    # Step 9: beta = (X'X - RZX'RZX)^{-1} (X'y - RZX' cu) via native solve#
    .xty# = mul# (transpose## (emlLMM.x##), emlLMM.y#)
    .rhs# = .xty# - mul# (.rzxt##, .cu#)
    .beta# = solve# (.dd##, .rhs#)

    # Step 10: cu_adj = cu - RZX * beta
    .cuAdj# = .cu# - mul# (.rzx##, .beta#)

    # Step 11: u = L_theta^{-T} cu_adj (back solve via native solve# on L')
    .u# = solve# (transpose## (.lTheta##), .cuAdj#)

    # Step 12: pwrss = ||cu_adj||^2 + ||y - X*beta - Z*Lambda*u||^2
    # But cwrss = ||cu_adj||^2 = inner(cuAdj, cuAdj) already captures
    # the penalized component. The full PWRSS from the augmented system:
    # pwrss = ||[u; y - X*beta - Z*Lambda*u]||^2
    .lambdaU# = mul# (emlConstructLambda.lambda##, .u#)
    .fitted# = mul# (emlLMM.x##, .beta#) + mul# (emlLMM.z##, .lambdaU#)
    .resid# = emlLMM.y# - .fitted#
    .pwrss = inner (.resid#, .resid#) + inner (.u#, .u#)

    # Step 13: log-determinant terms
    @emlTriangularLogDet: .lTheta##
    .ldL2 = emlTriangularLogDet.result

    @emlTriangularLogDet: .rx##
    .ldRX2 = emlTriangularLogDet.result

    # Step 14: deviance
    if emlLMM.useREML
        .nmp = .n - .p
        .value = .ldL2 + .ldRX2 + .nmp * (1 + ln (2 * pi * .pwrss / .nmp))
    else
        .value = .ldL2 + .n * (1 + ln (2 * pi * .pwrss / .n))
    endif

    label END_PROFDEV
    # Non-finite guard: a degenerate point (e.g. pwrss=0 -> ln(0)) can yield an
    # undefined objective. Praat comparisons against undefined are always false,
    # which would make the optimizer treat such a point as never-improving and
    # wander. Map any non-finite objective to the large-penalty sentinel so the
    # optimizer rejects it deterministically.
    if .value = undefined
        .value = 1e30
    endif
endproc

# ============================================================================
# @emlRecoverBetaSigma
# After optimization, recover fixed effects, sigma, random effects.
# Input: .thetaOpt# (optimal theta from BOBYQA)
# Reads: emlLMM.* shared state
# Output: .beta#, .sigma, .u#, .fitted#, .residuals#
#         .vcovBeta## (variance-covariance of beta)
#         .seBeta# (standard errors)
# ============================================================================
procedure emlRecoverBetaSigma: .thetaOpt#
    .error$ = ""
    .n = emlLMM.nObs
    .p = emlLMM.nFixedCols
    .q = emlLMM.nRandomCols

    # Reconstruct at optimal theta (same steps as profiled deviance)
    @emlConstructLambda: .thetaOpt#
    .lambda## = emlConstructLambda.lambda##

    .zl## = mul## (emlLMM.z##, .lambda##)
    .zlt## = transpose## (.zl##)
    .a## = mul## (.zlt##, .zl##)
    for .i from 1 to .q
        .a## [.i, .i] = .a## [.i, .i] + 1
    endfor

    @emlCholesky: .a##
    if emlCholesky.error$ <> ""
        .error$ = "Cholesky of Z'Z+I failed at optimum: " + emlCholesky.error$
        goto END_RECOVER
    endif
    .lTheta## = emlCholesky.l##

    .zty# = mul# (.zlt##, emlLMM.y#)
    .cu# = solve# (.lTheta##, .zty#)

    .ztx## = mul## (.zlt##, emlLMM.x##)
    .rzx## = solve## (.lTheta##, .ztx##)

    .xtx## = mul## (transpose## (emlLMM.x##), emlLMM.x##)
    .rzxt## = transpose## (.rzx##)
    .dd## = .xtx## - mul## (.rzxt##, .rzx##)

    @emlCholesky: .dd##
    if emlCholesky.error$ <> ""
        .error$ = "Downdated X'X not positive definite (rank-deficient fixed effects?): " + emlCholesky.error$
        goto END_RECOVER
    endif
    .rx## = emlCholesky.l##

    .xty# = mul# (transpose## (emlLMM.x##), emlLMM.y#)
    .rhs# = .xty# - mul# (.rzxt##, .cu#)
    .beta# = solve# (.dd##, .rhs#)

    .cuAdj# = .cu# - mul# (.rzx##, .beta#)
    .u# = solve# (transpose## (.lTheta##), .cuAdj#)

    .lambdaU# = mul# (.lambda##, .u#)
    .fitted# = mul# (emlLMM.x##, .beta#) + mul# (emlLMM.z##, .lambdaU#)
    .residuals# = emlLMM.y# - .fitted#
    .pwrss = inner (.residuals#, .residuals#) + inner (.u#, .u#)

    # Sigma
    if emlLMM.useREML
        .sigma = sqrt (.pwrss / (.n - .p))
    else
        .sigma = sqrt (.pwrss / .n)
    endif

    # Variance-covariance of beta: sigma^2 * (X'X - RZX'RZX)^{-1}
    .ddEye## = zero## (.p, .p)
    for .i from 1 to .p
        .ddEye## [.i, .i] = 1
    endfor
    .vcovBeta## = solve## (.dd##, .ddEye##)
    .sigSq = .sigma * .sigma
    .vcovBeta## = .vcovBeta## * .sigSq

    # Standard errors — diagonal extraction (p is small, loop is fine)
    .seBeta# = zero# (.p)
    for .i from 1 to .p
        .seBeta# [.i] = sqrt (.vcovBeta## [.i, .i])
    endfor

    # Log-determinants for model fit statistics
    @emlTriangularLogDet: .lTheta##
    .ldL2 = emlTriangularLogDet.result
    @emlTriangularLogDet: .rx##
    .ldRX2 = emlTriangularLogDet.result

    # Deviance at optimum
    if emlLMM.useREML
        .nmp = .n - .p
        .deviance = .ldL2 + .ldRX2 + .nmp * (1 + ln (2 * pi * .pwrss / .nmp))
    else
        .deviance = .ldL2 + .n * (1 + ln (2 * pi * .pwrss / .n))
    endif
    label END_RECOVER
endproc

# ============================================================================
# @emlLMM
# Main LMM fitting entry point.
# Input: .tableId, .formula$, .contrastCoding$, .useREML, .maxIter
# Output: all results via @emlRecoverBetaSigma plus model fit stats
# ============================================================================
procedure emlLMM: .tableId, .formula$, .contrastCoding$, .useREML, .maxIter
    .error$ = ""

    # Step 1: Parse formula
    @emlParseFormula: .formula$
    if emlParseFormula.error$ <> ""
        .error$ = "Formula parse error: " + emlParseFormula.error$
        goto END_LMM
    endif
    if emlParseFormula.nRandom = 0
        .error$ = "No random effects specified. Use lm() for fixed-effects only."
        goto END_LMM
    endif

    # Store metadata for post-hoc procedures
    .responseVar$ = emlParseFormula.response$

    # Step 2: Build model matrix X
    @emlModelMatrix: .tableId, .contrastCoding$

    # Step 3: Build response vector y
    selectObject: .tableId
    .nObs = Get number of rows
    .y# = zero# (.nObs)
    for .row from 1 to .nObs
        selectObject: .tableId
        .rv$ = Get value: .row, emlParseFormula.response$
        .y# [.row] = number (.rv$)
    endfor

    # Store shared state for profiled deviance
    .x## = emlModelMatrix.x##
    .nFixedCols = emlModelMatrix.p

    # Step 4: Build Z matrix and Lambda template
    @emlRandomEffectsZ: .tableId, .contrastCoding$
    .z## = emlRandomEffectsZ.z##
    .nRandomCols = emlRandomEffectsZ.q

    # Step 5: Set up BOBYQA
    .thetaSize = emlRandomEffectsZ.thetaSize
    .thetaInit# = zero# (.thetaSize)
    .thetaUpper# = zero# (.thetaSize)

    # Initialize theta: 1 on diagonal, 0 elsewhere
    for .j from 1 to emlRandomEffectsZ.nTerms
        .tStart = emlRandomEffectsZ.termThetaStart'.j'
        .m = emlRandomEffectsZ.termNEffects'.j'
        if emlRandomEffectsZ.termCorrelated'.j'
            .idx = 0
            for .row from 1 to .m
                for .col from 1 to .row
                    .idx = .idx + 1
                    if .row = .col
                        .thetaInit# [.tStart + .idx - 1] = 1
                    else
                        .thetaInit# [.tStart + .idx - 1] = 0
                    endif
                endfor
            endfor
        else
            for .diag from 1 to .m
                .thetaInit# [.tStart + .diag - 1] = 1
            endfor
        endif
    endfor

    # Upper bounds: large
    for .i from 1 to .thetaSize
        .thetaUpper# [.i] = 1e30
    endfor

    # Step 6: Optimize
    .rhoBeg = 1.0
    .rhoEnd = 1e-7
    .npt = 2 * .thetaSize + 1

    @emlBOBYQA: "emlProfiledDeviance", .thetaInit#,
        ... emlRandomEffectsZ.thetaLower#, .thetaUpper#,
        ... .rhoBeg, .rhoEnd, .maxIter, .npt

    .thetaOpt# = emlBOBYQA.xOpt#
    .converged = (emlBOBYQA.convergence = 0)
    .convergenceCode = emlBOBYQA.convergence
    .nEval = emlBOBYQA.nEval
    .optimError$ = emlBOBYQA.error$

    # Check for singular fit (any diagonal theta = 0)
    .isSingular = 0
    for .j from 1 to emlRandomEffectsZ.nTerms
        .tStart = emlRandomEffectsZ.termThetaStart'.j'
        .m = emlRandomEffectsZ.termNEffects'.j'
        if emlRandomEffectsZ.termCorrelated'.j'
            .idx = 0
            for .row from 1 to .m
                for .col from 1 to .row
                    .idx = .idx + 1
                    if .row = .col
                        if .thetaOpt# [.tStart + .idx - 1] < 1e-10
                            .isSingular = 1
                        endif
                    endif
                endfor
            endfor
        else
            for .diag from 1 to .m
                if .thetaOpt# [.tStart + .diag - 1] < 1e-10
                    .isSingular = 1
                endif
            endfor
        endif
    endfor

    # Step 7: Recover coefficients
    @emlRecoverBetaSigma: .thetaOpt#
    if emlRecoverBetaSigma.error$ <> ""
        .error$ = "Fit recovery failed: " + emlRecoverBetaSigma.error$
        .converged = 0
        goto END_LMM
    endif
    .beta# = emlRecoverBetaSigma.beta#
    .seBeta# = emlRecoverBetaSigma.seBeta#
    .sigma = emlRecoverBetaSigma.sigma
    .vcovBeta## = emlRecoverBetaSigma.vcovBeta##
    .u# = emlRecoverBetaSigma.u#
    .fitted# = emlRecoverBetaSigma.fitted#
    .residuals# = emlRecoverBetaSigma.residuals#
    .deviance = emlRecoverBetaSigma.deviance

    # t-values and p-values using Satterthwaite denominator df
    # Uses numerical approach matching R's lmerTest (profiled theta-only space)
    @emlSatterthwaiteDFNumerical: .thetaOpt#
    .dfBeta# = emlSatterthwaiteDFNumerical.df#

    .tBeta# = zero# (.nFixedCols)
    .pBeta# = zero# (.nFixedCols)
    for .i from 1 to .nFixedCols
        if .seBeta# [.i] > 0
            .tBeta# [.i] = .beta# [.i] / .seBeta# [.i]
            .absT = abs (.tBeta# [.i])
            .pBeta# [.i] = 2 * studentQ (.absT, .dfBeta# [.i])
        endif
    endfor

    # Fixed-effects-only predictions (for R-squared, prediction)
    .fittedFixed# = mul# (.x##, .beta#)

    # Model fit statistics
    if .useREML
        .nmp = .nObs - .nFixedCols
        .logLik = -0.5 * .deviance
    else
        .logLik = -0.5 * .deviance
    endif
    .nPars = .nFixedCols + .thetaSize + 1
    .aic = .deviance + 2 * .nPars
    .bic = .deviance + .nPars * ln (.nObs)

    # Variance-covariance of random effects
    # sigma^2 * Lambda * Lambda' gives the var-cov for each block
    for .j from 1 to emlRandomEffectsZ.nTerms
        .tStart = emlRandomEffectsZ.termThetaStart'.j'
        .m = emlRandomEffectsZ.termNEffects'.j'
        # Build template block
        .tmpl## = zero## (.m, .m)
        if emlRandomEffectsZ.termCorrelated'.j'
            .idx = 0
            for .row from 1 to .m
                for .col from 1 to .row
                    .idx = .idx + 1
                    .tmpl## [.row, .col] = .thetaOpt# [.tStart + .idx - 1]
                endfor
            endfor
        else
            for .diag from 1 to .m
                .tmpl## [.diag, .diag] = .thetaOpt# [.tStart + .diag - 1]
            endfor
        endif
        .varCov'.j'## = mul## (.tmpl##, transpose## (.tmpl##))
        .sigSq = .sigma * .sigma
        .varCov'.j'## = .varCov'.j'## * .sigSq
    endfor

    label END_LMM
endproc
# ============================================================================
# PHASE 3D: INFERENCE, DIAGNOSTICS, AND PREDICTION
# ============================================================================
# Added: 15 May 2026 (Phase 3D session)
# Procedures:
#   @emlVcovAtTheta        — Vcov(beta) at arbitrary theta
#   @emlSatterthwaiteDF    — Satterthwaite denominator df
#   @emlKenwardRoger       — KR bias-corrected vcov and df
#   @emlWaldCI             — Wald confidence intervals
#   @emlProfileCI          — Profile likelihood CIs
#   @emlBootstrapCI        — Parametric bootstrap CIs
#   @emlLikelihoodRatioTest — LRT with boundary correction
#   @emlJohnsonR2          — Marginal and conditional R-squared
#   @emlLMMResiduals       — Raw, Pearson, scaled residuals
#   @emlLMMInfluence       — Hat values, Cook's D, DFBETAS
#   @emlLMMPredict         — New-data predictions
#   @emlLMMSummary         — Formatted summary output (lmerTest style)
# ============================================================================

# ============================================================================
# @emlVcovAtTheta
# Compute vcov(beta) and sigma at an arbitrary theta value.
# Reads shared state from emlLMM.* namespace (x##, y#, z##, etc.)
# Input: .theta#
# Output: .vcov## (p × p), .sigma, .seBeta#, .beta#
# ============================================================================
procedure emlVcovAtTheta: .theta#
    .error$ = ""
    .nVal = emlLMM.nObs
    .pVal = emlLMM.nFixedCols
    .qVal = emlLMM.nRandomCols

    @emlConstructLambda: .theta#
    .lambda## = emlConstructLambda.lambda##

    .zl## = mul## (emlLMM.z##, .lambda##)
    .zlt## = transpose## (.zl##)
    .zltzl## = mul## (.zlt##, .zl##)
    for .ii from 1 to .qVal
        .zltzl## [.ii, .ii] = .zltzl## [.ii, .ii] + 1
    endfor
    @emlCholesky: .zltzl##
    if emlCholesky.error$ <> ""
        .error$ = "Cholesky of Z'Z+I failed: " + emlCholesky.error$
        goto END_VCOVATTHETA
    endif
    .lTheta## = emlCholesky.l##

    .zty# = mul# (.zlt##, emlLMM.y#)
    .cu# = solve# (.lTheta##, .zty#)

    .ztx## = mul## (.zlt##, emlLMM.x##)
    .rzx## = solve## (.lTheta##, .ztx##)

    .xtx## = mul## (transpose## (emlLMM.x##), emlLMM.x##)
    .rxSq## = .xtx## - mul## (transpose## (.rzx##), .rzx##)
    @emlCholesky: .rxSq##
    if emlCholesky.error$ <> ""
        .error$ = "Downdated X'X not positive definite (rank-deficient fixed effects?): " + emlCholesky.error$
        goto END_VCOVATTHETA
    endif
    .rx## = emlCholesky.l##

    .xty# = mul# (transpose## (emlLMM.x##), emlLMM.y#)
    .rztCu# = mul# (transpose## (.rzx##), .cu#)
    .rhs# = .xty# - .rztCu#
    .beta# = solve# (.rxSq##, .rhs#)

    .cuAdj# = .cu# - mul# (.rzx##, .beta#)
    .uVec# = solve# (transpose## (.lTheta##), .cuAdj#)

    .lambdaU# = mul# (.lambda##, .uVec#)
    .fittedVals# = mul# (emlLMM.x##, .beta#) + mul# (emlLMM.z##, .lambdaU#)
    .residVals# = emlLMM.y# - .fittedVals#
    .pwrss = inner (.residVals#, .residVals#) + inner (.uVec#, .uVec#)

    if emlLMM.useREML
        .sigma = sqrt (.pwrss / (.nVal - .pVal))
    else
        .sigma = sqrt (.pwrss / .nVal)
    endif

    .rxEye## = zero## (.pVal, .pVal)
    for .ii from 1 to .pVal
        .rxEye## [.ii, .ii] = 1
    endfor
    .vcov## = solve## (.rxSq##, .rxEye##)
    .sigSq = .sigma * .sigma
    .vcov## = .vcov## * .sigSq

    .seBeta# = zero# (.pVal)
    for .ii from 1 to .pVal
        .seBeta# [.ii] = sqrt (.vcov## [.ii, .ii])
    endfor
    label END_VCOVATTHETA
endproc

# ============================================================================
# @emlSatterthwaiteDF
# Compute Satterthwaite denominator degrees of freedom for each fixed effect.
# Must be called after @emlLMM has set shared state and optimal theta.
# Input: .thetaOpt# (optimal theta from BOBYQA)
# Output: .df# (vector of df, one per fixed effect)
# ============================================================================
# ============================================================================
# @emlSatterthwaiteDF (CORRECTED)
# Compute Satterthwaite denominator df using the expected information matrix
# and analytical gradient, matching lmerTest's implementation.
# Uses n×n matrices; feasible for n ≤ ~2000.
# Must be called after @emlLMM has set shared state and optimal theta.
# Input: .thetaOpt#
# Output: .df# (vector of df, one per fixed effect)
# ============================================================================
# ============================================================================
# @emlSatterthwaiteDF — Woodbury formulation
# Avoids all n×n matrix operations. Cost: O(n*q^2) instead of O(n^3).
# Gives identical results to the direct formulation.
# ============================================================================
# !!! UNUSED ALTERNATE ESTIMATOR — DO NOT WIRE INTO dfBeta# WITHOUT CARE !!!
# The engine uses @emlSatterthwaiteDFNumerical (below) for dfBeta#; this
# analytical estimator is retained only as a cross-check reference. It uses a
# DIFFERENT (theta, sigma^2) parameterization from the numerical version, so
# swapping it in for dfBeta# would silently change the df estimator and its
# results. Kept (not deleted) deliberately as a documented alternate; if you
# are here to "use" it, confirm the parameterization matches first. (Rule 35
# L1: marked, not dead-removed.)
# ============================================================================
procedure emlSatterthwaiteDF: .thetaOpt#
    .nVal = emlLMM.nObs
    .pVal = emlLMM.nFixedCols
    .qVal = emlLMM.nRandomCols
    .sigma = emlLMM.sigma
    .sigSq = .sigma * .sigma

    # Step 1: Woodbury factors for V^{-1}
    # V = σ²(ZΛΛ'Z' + I), so V^{-1} = (1/σ²)(I - ZΛ·M·Λ'Z')
    # where M = (I + Λ'Z'ZΛ)^{-1}  (q×q)
    @emlConstructLambda: .thetaOpt#
    .lambda## = emlConstructLambda.lambda##
    # ZΛ (n×q)
    .zl## = mul## (emlLMM.z##, .lambda##)
    # Z'Z (q×q) via Λ'Z'ZΛ
    .zltzl## = mul## (transpose## (.zl##), .zl##)
    # (I + Λ'Z'ZΛ) (q×q)
    for .ii from 1 to .qVal
        .zltzl## [.ii, .ii] = .zltzl## [.ii, .ii] + 1
    endfor
    # M = (I + ZL'ZL)^{-1} (q×q)
    .mEye## = zero## (.qVal, .qVal)
    for .ii from 1 to .qVal
        .mEye## [.ii, .ii] = 1
    endfor
    .m## = solve## (.zltzl##, .mEye##)

    # Precompute ZΛM (n×q) — key Woodbury factor
    .zlM## = mul## (.zl##, .m##)

    # Step 2: V^{-1}X without forming n×n V^{-1}
    # V^{-1}X = (1/σ²)(X - ZΛ·M·Λ'Z'X) = (1/σ²)(X - ZLM·ZL'X)
    .zltX## = mul## (transpose## (.zl##), emlLMM.x##)
    .vInvX## = emlLMM.x## - mul## (.zlM##, .zltX##)
    .vInvX## = (1 / .sigSq) * .vInvX##

    # Step 3: A = (X'V^{-1}X)^{-1} (p×p) via native solve##
    .xtvInvX## = mul## (transpose## (emlLMM.x##), .vInvX##)
    .aEye## = zero## (.pVal, .pVal)
    for .ii from 1 to .pVal
        .aEye## [.ii, .ii] = 1
    endfor
    .a## = solve## (.xtvInvX##, .aEye##)

    # Step 4: Compute SigmaG derivatives with Cholesky chain rule
    # For theta_r corresponding to Lambda[row,col]:
    #   dSigma/dtheta_r = E_{row,col}*L' + L*E_{col,row}  (mEff × mEff)
    #   dV/dtheta_r = sigma^2 * Z * (dSigma ⊗ I_nLev) * Z'
    #              = sigma^2 * sum_l Z_l * dG_r * Z_l'
    #
    # R_r = X'V^{-1} * dV/dtheta_r * V^{-1}X
    #     = sigma^2 * sum_l (vInvX'*Z_l) * dG_r * (vInvX'*Z_l)'
    #
    # Information matrix trace:
    #   trace(P*SigmaG_r*P*SigmaG_s) = sigma^4 * sum_{l,m}
    #     trace(dG_r * H_{l,m} * dG_s * H_{m,l})
    #   where H_{l,m} = Z_l' * P * Z_m (mEff × mEff)

    .nVarPars = 0
    for .jj from 1 to emlRandomEffectsZ.nTerms
        .mEff = emlRandomEffectsZ.termNEffects'.jj'
        if emlRandomEffectsZ.termCorrelated'.jj'
            .nVarPars = .nVarPars + .mEff * (.mEff + 1) / 2
        else
            .nVarPars = .nVarPars + .mEff
        endif
    endfor
    .nVarParsTotal = .nVarPars + 1

    # --- Step 4A: Precompute per-level data for all terms ---
    for .jj from 1 to emlRandomEffectsZ.nTerms
        .zStart = emlRandomEffectsZ.termStart'.jj'
        .mEff = emlRandomEffectsZ.termNEffects'.jj'
        .nLev = emlRandomEffectsZ.termNLevels'.jj'
        .tStart = emlRandomEffectsZ.termThetaStart'.jj'
        .corr = emlRandomEffectsZ.termCorrelated'.jj'

        # Extract Cholesky block L for this term (mEff × mEff)
        .tL## = zero## (.mEff, .mEff)
        if .corr
            .tIdx = 0
            for .tr from 1 to .mEff
                for .tc from 1 to .tr
                    .tIdx = .tIdx + 1
                    .tL## [.tr, .tc] = .thetaOpt# [.tStart + .tIdx - 1]
                endfor
            endfor
        else
            for .td from 1 to .mEff
                .tL## [.td, .td] = .thetaOpt# [.tStart + .td - 1]
            endfor
        endif
        # Store Cholesky block per term for later use
        .termL'.jj'## = .tL##

        # For each level: extract Z_l (n × mEff), compute W_l and QZ_l
        for .lv from 1 to .nLev
            # Extract Z_l: columns from Z for this level
            .zLev## = zero## (.nVal, .mEff)
            for .ef from 1 to .mEff
                .srcCol = .zStart + (.lv - 1) * .mEff + .ef - 1
                .col# = rowSums# (part## (emlLMM.z##, 1, .nVal, .srcCol, .srcCol))
                for .ii from 1 to .nVal
                    .zLev## [.ii, .ef] = .col# [.ii]
                endfor
            endfor
            .zLev'.jj'_'.lv'## = .zLev##

            # W_l = vInvX' * Z_l (p × mEff) — for R_r computation
            .wLev'.jj'_'.lv'## = mul## (transpose## (.vInvX##), .zLev##)

            # QZ_l = P * Z_l (n × mEff) via Woodbury
            # V^{-1}*Z_l = (1/σ²)(Z_l - ZΛM·ZΛ'Z_l)
            .zltZl## = mul## (transpose## (.zl##), .zLev##)
            .vInvZl## = (1 / .sigSq) * (.zLev## - mul## (.zlM##, .zltZl##))
            # P*Z_l = V^{-1}*Z_l - vInvX*A*vInvX'*Z_l
            .vInvXtZl## = mul## (transpose## (.vInvX##), .zLev##)
            .qzLev'.jj'_'.lv'## = .vInvZl## - mul## (mul## (.vInvX##, .a##), .vInvXtZl##)
        endfor
    endfor

    # --- Step 4B: Compute dG_r and R_r for each theta parameter ---
    .rIdx = 0
    for .jj from 1 to emlRandomEffectsZ.nTerms
        .mEff = emlRandomEffectsZ.termNEffects'.jj'
        .nLev = emlRandomEffectsZ.termNLevels'.jj'
        .corr = emlRandomEffectsZ.termCorrelated'.jj'
        .tL## = .termL'.jj'##

        if .corr
            for .row from 1 to .mEff
                for .col from 1 to .row
                    .rIdx = .rIdx + 1
                    # dG_r = E_{row,col}*L' + L*E_{col,row} (mEff × mEff)
                    .dG## = zero## (.mEff, .mEff)
                    # E_{row,col}*L': row .row gets L'[col,:] = L[:,col]
                    for .k from 1 to .mEff
                        .dG## [.row, .k] = .dG## [.row, .k] + .tL## [.k, .col]
                    endfor
                    # L*E_{col,row}: column .row gets L[:,col]
                    for .k from 1 to .mEff
                        .dG## [.k, .row] = .dG## [.k, .row] + .tL## [.k, .col]
                    endfor
                    .dGStore'.rIdx'## = .dG##

                    # R_r = σ² * sum_l W_l * dG_r * W_l' (p × p)
                    .rMat'.rIdx'## = zero## (.pVal, .pVal)
                    for .lv from 1 to .nLev
                        .wl## = .wLev'.jj'_'.lv'##
                        .wldG## = mul## (.wl##, .dG##)
                        .rMat'.rIdx'## = .rMat'.rIdx'## + mul## (.wldG##, transpose## (.wl##))
                    endfor
                    .rMat'.rIdx'## = .sigSq * .rMat'.rIdx'##

                    # Store term index for trace computation
                    .thetaTerm'.rIdx' = .jj
                endfor
            endfor
        else
            for .diag from 1 to .mEff
                .rIdx = .rIdx + 1
                # dG = [[2*theta_diag]] for scalar case
                .dG## = zero## (.mEff, .mEff)
                .dG## [.diag, .diag] = 2 * .tL## [.diag, .diag]
                .dGStore'.rIdx'## = .dG##

                # R_r = σ² * sum_l W_l * dG * W_l'
                # For mEff=1: σ² * 2*theta * sum_l w_l*w_l' = σ²*2*theta * (vInvX'*Z_eff)*(vInvX'*Z_eff)'
                .rMat'.rIdx'## = zero## (.pVal, .pVal)
                for .lv from 1 to .nLev
                    .wl## = .wLev'.jj'_'.lv'##
                    .wldG## = mul## (.wl##, .dG##)
                    .rMat'.rIdx'## = .rMat'.rIdx'## + mul## (.wldG##, transpose## (.wl##))
                endfor
                .rMat'.rIdx'## = .sigSq * .rMat'.rIdx'##
                .thetaTerm'.rIdx' = .jj
            endfor
        endif
    endfor

    # Residual variance parameter: dV/dσ² = V/σ² — but in the theta/σ² parameterization,
    # the residual parameter contributes SigmaG_res = I (the identity).
    # R_res = X'V^{-1}·I·V^{-1}X = X'V^{-2}X
    .rIdx = .rIdx + 1
    .resIdx = .rIdx
    .zltVInvX## = mul## (transpose## (.zl##), .vInvX##)
    .vSqInvX## = (1 / .sigSq) * (.vInvX## - mul## (.zlM##, .zltVInvX##))
    .rMat'.rIdx'## = mul## (transpose## (.vInvX##), .vInvX##)

    # --- Step 5: Information matrix I[r,s] = 0.5 * trace(P·SigmaG_r·P·SigmaG_s) ---
    .infoMat## = zero## (.nVarParsTotal, .nVarParsTotal)

    # Theta × Theta: for each pair (r,s), compute trace using per-level H matrices
    # H_{l,m} = Z_l' * QZ_m (mEff_r × mEff_s or mEff × mEff if same term)
    # trace(P*SigmaG_r*P*SigmaG_s) = σ⁴ * sum_{l,m} trace(dG_r * H_{l,m}^{rr} * dG_s * H_{m,l}^{ss})
    # where H_{l,m}^{rr,ss} = Z_l^{term_r}' * QZ_m^{term_s}

    for .rr from 1 to .nVarPars
        for .ss from .rr to .nVarPars
            .termR = .thetaTerm'.rr'
            .termS = .thetaTerm'.ss'
            .nLevR = emlRandomEffectsZ.termNLevels'.termR'
            .nLevS = emlRandomEffectsZ.termNLevels'.termS'
            .dGr## = .dGStore'.rr'##
            .dGs## = .dGStore'.ss'##

            .trSum = 0
            for .l1 from 1 to .nLevR
                for .l2 from 1 to .nLevS
                    # H_{l1,l2} = Z_{l1}^{termR}' * QZ_{l2}^{termS} (mEffR × mEffS)
                    .h## = mul## (transpose## (.zLev'.termR'_'.l1'##), .qzLev'.termS'_'.l2'##)
                    # H_{l2,l1} = Z_{l2}^{termS}' * QZ_{l1}^{termR} = H_{l1,l2}'
                    .ht## = transpose## (mul## (transpose## (.zLev'.termS'_'.l2'##), .qzLev'.termR'_'.l1'##))
                    # trace(dG_r * H * dG_s * H') = trace of product of small matrices
                    .prod## = mul## (.dGr##, mul## (.h##, mul## (.dGs##, .ht##)))
                    .trVal = 0
                    for .ii from 1 to numberOfRows (.prod##)
                        .trVal = .trVal + .prod## [.ii, .ii]
                    endfor
                    .trSum = .trSum + .trVal
                endfor
            endfor
            .infoMat## [.rr, .ss] = 0.5 * .sigSq * .sigSq * .trSum
            .infoMat## [.ss, .rr] = .infoMat## [.rr, .ss]
        endfor
    endfor

    # Theta × Residual: trace(P·SigmaG_r·P·I) = σ² * sum_l trace(dG_r * QZ_l' * QZ_l)
    for .rr from 1 to .nVarPars
        .termR = .thetaTerm'.rr'
        .nLevR = emlRandomEffectsZ.termNLevels'.termR'
        .dGr## = .dGStore'.rr'##
        .trSum = 0
        for .lv from 1 to .nLevR
            .qzl## = .qzLev'.termR'_'.lv'##
            .qtq## = mul## (transpose## (.qzl##), .qzl##)
            .prod## = mul## (.dGr##, .qtq##)
            .trVal = 0
            for .ii from 1 to numberOfRows (.prod##)
                .trVal = .trVal + .prod## [.ii, .ii]
            endfor
            .trSum = .trSum + .trVal
        endfor
        .infoMat## [.rr, .resIdx] = 0.5 * .sigSq * .trSum
        .infoMat## [.resIdx, .rr] = .infoMat## [.rr, .resIdx]
    endfor

    # Residual × Residual: trace(P²) — unchanged from previous version
    .b## = mul## (transpose## (.zl##), .zl##)
    .bm## = mul## (.b##, .m##)
    .trBM = 0
    for .ii from 1 to .qVal
        .trBM = .trBM + .bm## [.ii, .ii]
    endfor
    .bmbm## = mul## (.bm##, .bm##)
    .trBMBM = 0
    for .ii from 1 to .qVal
        .trBMBM = .trBMBM + .bmbm## [.ii, .ii]
    endfor
    .trVinv2 = (1 / (.sigSq * .sigSq)) * (.nVal - 2 * .trBM + .trBMBM)
    .zltVinvX2## = mul## (transpose## (.zl##), .vInvX##)
    .v2InvX## = (1 / .sigSq) * (.vInvX## - mul## (.zlM##, .zltVinvX2##))
    .xtV2X## = mul## (transpose## (emlLMM.x##), .v2InvX##)
    .zltV2X## = mul## (transpose## (.zl##), .v2InvX##)
    .v3InvX## = (1 / .sigSq) * (.v2InvX## - mul## (.zlM##, .zltV2X##))
    .xtV3X## = mul## (transpose## (emlLMM.x##), .v3InvX##)
    .trAxtV3X = sum (.a## * transpose## (.xtV3X##))
    .aXtV2X## = mul## (.a##, .xtV2X##)
    .aXtV2X_sq## = mul## (.aXtV2X##, .aXtV2X##)
    .trAxtV2X_sq = 0
    for .ii from 1 to .pVal
        .trAxtV2X_sq = .trAxtV2X_sq + .aXtV2X_sq## [.ii, .ii]
    endfor
    .trP2 = .trVinv2 - 2 * .trAxtV3X + .trAxtV2X_sq
    .infoMat## [.resIdx, .resIdx] = 0.5 * .trP2


    # Step 6: W = I^{-1} via native solve##
    .wEye## = zero## (.nVarParsTotal, .nVarParsTotal)
    for .ii from 1 to .nVarParsTotal
        .wEye## [.ii, .ii] = 1
    endfor
    .w## = solve## (.infoMat##, .wEye##)

    # Step 7: Satterthwaite df per fixed effect
    .df# = zero# (.pVal)
    for .jj from 1 to .pVal
        .vVal = .a## [.jj, .jj]
        # Extract row j of A as a vector (A is symmetric, so row = col)
        .aj# = columnSums# (part## (.a##, .jj, .jj, 1, .pVal))
        .gVec# = zero# (.nVarParsTotal)
        for .rr from 1 to .nVarParsTotal
            # A[j,:] · R_r · A[:,j] = inner(aj, R_r · aj)
            .gVec# [.rr] = inner (.aj#, mul# (.rMat'.rr'##, .aj#))
        endfor
        .quadForm = inner (.gVec#, mul# (.w##, .gVec#))
        if .quadForm > 0
            .df# [.jj] = 2 * .vVal * .vVal / .quadForm
        else
            .df# [.jj] = 1e6
        endif
        if .df# [.jj] < 1
            .df# [.jj] = 1
        endif
    endfor

    # Store for KR reuse
    .vInvStored## = zero## (1, 1)
    .aStored## = .a##
    .pMatStored## = zero## (1, 1)

    # Store Woodbury factors for KR
    .zlStored## = .zl##
    .mStored## = .m##
    .zlMStored## = .zlM##
    .vInvXStored## = .vInvX##
endproc

# ============================================================================
# @emlDevfunVP
# Compute the UN-PROFILED deviance as a function of (theta, sigma).
# This matches R's lmerTest::devfun_vp: sigma is a free parameter,
# not profiled out from theta. Used for the Hessian in Satterthwaite df.
# Input:  .varpar# (vector: [theta_1, ..., theta_k, sigma])
# Output: .value   (un-profiled REML or ML deviance)
# ============================================================================
procedure emlDevfunVP: .varpar#
    .nVP = size (.varpar#)
    .sigma = .varpar# [.nVP]
    .sigSq = .sigma * .sigma
    .nTheta = .nVP - 1
    .theta# = zero# (.nTheta)
    for .ii from 1 to .nTheta
        .theta# [.ii] = .varpar# [.ii]
    endfor

    # Evaluate profiled deviance to get ldL2, ldRX2, pwrss
    @emlProfiledDeviance: .theta#

    if emlProfiledDeviance.value >= 1e29
        .value = 1e30
        goto END_DEVFUNVP
    endif

    .ldL2 = emlProfiledDeviance.ldL2
    .ldRX2 = emlProfiledDeviance.ldRX2
    .pwrss = emlProfiledDeviance.pwrss
    .nVal = emlLMM.nObs
    .pVal = emlLMM.nFixedCols

    if emlLMM.useREML
        .nmp = .nVal - .pVal
        .value = .ldL2 + .ldRX2 + .pwrss / .sigSq + .nmp * ln (2 * pi * .sigSq)
    else
        .value = .ldL2 + .pwrss / .sigSq + .nVal * ln (2 * pi * .sigSq)
    endif

    label END_DEVFUNVP
endproc

# ============================================================================
# @emlCovbetaDiag
# Compute the diagonal of vcov_beta = sigma^2 * inv(RX * RX') at
# arbitrary (theta, sigma). sigma is treated as an independent parameter
# (not profiled from theta). This matches R's lmerTest::get_covbeta.
# Input:  .varpar# (vector: [theta_1, ..., theta_k, sigma])
# Output: .diag#   (vector of vcov diagonal, length = nFixedCols)
# ============================================================================
procedure emlCovbetaDiag: .varpar#
    .nVP = size (.varpar#)
    .sigma = .varpar# [.nVP]
    .sigSq = .sigma * .sigma
    .nTheta = .nVP - 1
    .theta# = zero# (.nTheta)
    for .ii from 1 to .nTheta
        .theta# [.ii] = .varpar# [.ii]
    endfor

    # Get RX by evaluating profiled deviance at this theta
    @emlProfiledDeviance: .theta#
    .pVal = emlLMM.nFixedCols

    if emlProfiledDeviance.value >= 1e29
        .diag# = zero# (.pVal)
        for .ii from 1 to .pVal
            .diag# [.ii] = 1e20
        endfor
        goto END_COVBETADIAG
    endif

    # vcov_beta = sigma^2 * inv(RX * RX')
    .rx## = emlProfiledDeviance.rx##
    .rxrxt## = mul## (.rx##, transpose## (.rx##))
    .eye## = zero## (.pVal, .pVal)
    for .ii from 1 to .pVal
        .eye## [.ii, .ii] = 1
    endfor
    .inv## = solve## (.rxrxt##, .eye##)

    .diag# = zero# (.pVal)
    for .ii from 1 to .pVal
        .diag# [.ii] = .sigSq * .inv## [.ii, .ii]
    endfor

    label END_COVBETADIAG
endproc

# ============================================================================
# @emlSatterthwaiteDFNumerical
# Compute Satterthwaite denominator df using numerical derivatives,
# exactly matching R's lmerTest approach:
#   - varpar = (theta, sigma) — full un-profiled parameterization
#   - Numerical Jacobian of vcov_beta diagonal w.r.t. varpar
#   - Numerical Hessian of the un-profiled deviance w.r.t. varpar
#   - vcov_varpar = 2 * H^{-1} (asymptotic variance of varpar)
#   - df = 2 * v^2 / (g' * vcov_varpar * g)
#
# The analytical @emlSatterthwaiteDF uses the expected Fisher information
# in the (theta, sigma^2) space with trace-based computation. This gives
# values very close to Kenward-Roger (which uses the same framework).
# The numerical version here matches lmerTest by using observed information
# (Hessian) in the (theta, sigma) space, which gives slightly different df.
#
# Input:  .thetaOpt# (optimal theta from BOBYQA)
# Output: .df# (vector of df, one per fixed effect)
# ============================================================================
procedure emlSatterthwaiteDFNumerical: .thetaOpt#
    .nTheta = size (.thetaOpt#)
    .pVal = emlLMM.nFixedCols
    .sigmaOpt = emlLMM.sigma

    # Full variance parameter vector: (theta, sigma)
    .nVP = .nTheta + 1
    .varparOpt# = zero# (.nVP)
    for .k from 1 to .nTheta
        .varparOpt# [.k] = .thetaOpt# [.k]
    endfor
    .varparOpt# [.nVP] = .sigmaOpt

    # Step 1: vcov diagonal at optimal varpar
    @emlCovbetaDiag: .varparOpt#
    .vcov0# = emlCovbetaDiag.diag#

    # Step 2: Numerical Jacobian of vcov[j,j] w.r.t. varpar
    # Central differences with adaptive step size
    .grad## = zero## (.pVal, .nVP)
    for .k from 1 to .nVP
        .absVk = abs (.varparOpt# [.k])
        if .absVk > 1e-3
            .hVal = .absVk * 1e-4
        else
            .hVal = 1e-4
        endif

        .vpPlus# = .varparOpt#
        .vpPlus# [.k] = .vpPlus# [.k] + .hVal

        .vpMinus# = .varparOpt#
        .vpMinus# [.k] = .vpMinus# [.k] - .hVal

        @emlCovbetaDiag: .vpPlus#
        .vPlus# = emlCovbetaDiag.diag#

        @emlCovbetaDiag: .vpMinus#
        .vMinus# = emlCovbetaDiag.diag#

        for .jj from 1 to .pVal
            .grad## [.jj, .k] = (.vPlus# [.jj] - .vMinus# [.jj]) / (2 * .hVal)
        endfor
    endfor

    # Step 3: Numerical Hessian of un-profiled deviance w.r.t. varpar
    @emlDevfunVP: .varparOpt#
    .dev0 = emlDevfunVP.value

    .hess## = zero## (.nVP, .nVP)

    for .k from 1 to .nVP
        .absVk = abs (.varparOpt# [.k])
        if .absVk > 1e-3
            .hk = .absVk * 1e-4
        else
            .hk = 1e-4
        endif

        .vpPlus# = .varparOpt#
        .vpPlus# [.k] = .vpPlus# [.k] + .hk
        @emlDevfunVP: .vpPlus#
        .devPlus = emlDevfunVP.value

        .vpMinus# = .varparOpt#
        .vpMinus# [.k] = .vpMinus# [.k] - .hk
        @emlDevfunVP: .vpMinus#
        .devMinus = emlDevfunVP.value

        .hess## [.k, .k] = (.devPlus - 2 * .dev0 + .devMinus) / (.hk * .hk)

        for .l from .k + 1 to .nVP
            .absVl = abs (.varparOpt# [.l])
            if .absVl > 1e-3
                .hl = .absVl * 1e-4
            else
                .hl = 1e-4
            endif

            .t1# = .varparOpt#
            .t1# [.k] = .t1# [.k] + .hk
            .t1# [.l] = .t1# [.l] + .hl
            @emlDevfunVP: .t1#
            .fpp = emlDevfunVP.value

            .t2# = .varparOpt#
            .t2# [.k] = .t2# [.k] + .hk
            .t2# [.l] = .t2# [.l] - .hl
            @emlDevfunVP: .t2#
            .fpm = emlDevfunVP.value

            .t3# = .varparOpt#
            .t3# [.k] = .t3# [.k] - .hk
            .t3# [.l] = .t3# [.l] + .hl
            @emlDevfunVP: .t3#
            .fmp = emlDevfunVP.value

            .t4# = .varparOpt#
            .t4# [.k] = .t4# [.k] - .hk
            .t4# [.l] = .t4# [.l] - .hl
            @emlDevfunVP: .t4#
            .fmm = emlDevfunVP.value

            .hess## [.k, .l] = (.fpp - .fpm - .fmp + .fmm) / (4 * .hk * .hl)
            .hess## [.l, .k] = .hess## [.k, .l]
        endfor
    endfor

    # Step 4: vcov_varpar = 2 * H^{-1}
    # (matches lmerTest: res@vcov_varpar <- 2 * h_inv)
    .hInvEye## = zero## (.nVP, .nVP)
    for .ii from 1 to .nVP
        .hInvEye## [.ii, .ii] = 1
    endfor
    .hInv## = solve## (.hess##, .hInvEye##)
    .vcovVP## = 2 * .hInv##

    # Step 5: Satterthwaite df = 2 * v^2 / (g' * vcov_varpar * g)
    .df# = zero# (.pVal)
    for .jj from 1 to .pVal
        .gj# = zero# (.nVP)
        for .k from 1 to .nVP
            .gj# [.k] = .grad## [.jj, .k]
        endfor

        .quadForm = inner (.gj#, mul# (.vcovVP##, .gj#))

        if .quadForm > 0
            .df# [.jj] = 2 * .vcov0# [.jj] * .vcov0# [.jj] / .quadForm
        else
            .df# [.jj] = 1e6
        endif
        if .df# [.jj] < 1
            .df# [.jj] = 1
        endif
    endfor
endproc

# ============================================================================
# @emlKenwardRoger
# Compute Kenward-Roger bias-corrected vcov and adjusted df.
# Must be called after @emlLMM has completed.
# Uses n×n matrices; feasible for n ≤ ~2000.
# Output: .vcovAdj## (p × p), .dfKR# (vector of KR df)
# ============================================================================
procedure emlKenwardRoger
    .nVal = emlLMM.nObs
    .pVal = emlLMM.nFixedCols
    .sigma = emlLMM.sigma
    .sigSq = .sigma * .sigma
    .thetaOpt# = emlLMM.thetaOpt#

    # Large-N guard (E4): the dense Kenward-Roger path forms and inverts the
    # n×n marginal covariance V (O(n^3)) and builds n×n P/SigmaG products, so it
    # becomes impractical past a few hundred observations and would hang for
    # many minutes near n=2000. Rather than hang silently, fall back to the
    # Satterthwaite df (scalable, already matching lmerTest) and the uncorrected
    # vcov, with an explicit warning. A sparse/Woodbury KR reformulation is the
    # proper fix for bias-corrected inference at large n and is tracked as a
    # dedicated numerical task (it must be verified against pbkrtest across all
    # RE structures before it can be trusted).
    .krMaxN = 800
    if .nVal > .krMaxN
        .dfKR# = zero# (.pVal)
        for .jj from 1 to .pVal
            .dfKR# [.jj] = emlLMM.dfBeta# [.jj]
        endfor
        .vcovAdj## = emlLMM.vcovBeta##
        .largeNFallback = 1
        .warning$ = "Kenward-Roger skipped at n=" + string$ (.nVal)
            ... + " (> " + string$ (.krMaxN) + "): using Satterthwaite df and "
            ... + "uncorrected vcov (dense KR is O(n^3))."
        appendInfoLine: .warning$
        goto END_KR
    endif
    .largeNFallback = 0

    # Step 1: Build V = sigma^2 * (Z Lambda Lambda' Z' + I) — n × n
    @emlConstructLambda: .thetaOpt#
    .lambda## = emlConstructLambda.lambda##
    .lambdaLt## = mul## (.lambda##, transpose## (.lambda##))
    .zLLtZt## = mul## (mul## (emlLMM.z##, .lambdaLt##), transpose## (emlLMM.z##))
    # V = σ²(ZΛΛ'Z' + I) — native scalar multiply + diagonal add
    .v## = .sigSq * .zLLtZt##
    for .ii from 1 to .nVal
        .v## [.ii, .ii] = .v## [.ii, .ii] + .sigSq
    endfor

    # Step 2: V inverse via native solve##
    .eye## = zero## (.nVal, .nVal)
    for .ii from 1 to .nVal
        .eye## [.ii, .ii] = 1
    endfor
    .vInv## = solve## (.v##, .eye##)

    # Step 3: A = (X' V^{-1} X)^{-1} via native solve##
    .xTvInv## = mul## (transpose## (emlLMM.x##), .vInv##)
    .xTvInvX## = mul## (.xTvInv##, emlLMM.x##)
    .aEye## = zero## (.pVal, .pVal)
    for .ii from 1 to .pVal
        .aEye## [.ii, .ii] = 1
    endfor
    .a## = solve## (.xTvInvX##, .aEye##)

    # Step 4: P = V^{-1} - V^{-1} X A X' V^{-1}
    .vInvX## = mul## (.vInv##, emlLMM.x##)
    .vInvXA## = mul## (.vInvX##, .a##)
    .pMat## = .vInv## - mul## (.vInvXA##, transpose## (.vInvX##))

    # Step 5: Build SigmaG matrices (derivatives of V w.r.t. variance components)
    # Count variance parameters
    .nVarPars = 0
    for .jj from 1 to emlRandomEffectsZ.nTerms
        .mEff = emlRandomEffectsZ.termNEffects'.jj'
        if emlRandomEffectsZ.termCorrelated'.jj'
            .nVarPars = .nVarPars + .mEff * (.mEff + 1) / 2
        else
            .nVarPars = .nVarPars + .mEff
        endif
    endfor
    # Plus 1 for sigma^2 residual
    .nVarParsTotal = .nVarPars + 1

    # For each variance parameter, compute R_r = X' P SigmaG_r P X (p×p)
    # and store in indexed matrices
    # Also compute information matrix I[r,s] = 0.5 * trace(P SigmaG_r P SigmaG_s)

    # First build and apply each SigmaG
    .rIdx = 0
    for .jj from 1 to emlRandomEffectsZ.nTerms
        .zStart = emlRandomEffectsZ.termStart'.jj'
        .mEff = emlRandomEffectsZ.termNEffects'.jj'
        .nLev = emlRandomEffectsZ.termNLevels'.jj'

        if emlRandomEffectsZ.termCorrelated'.jj'
            # Correlated: unique elements of G (lower triangle)
            for .row from 1 to .mEff
                for .col from 1 to .row
                    .rIdx = .rIdx + 1
                    # Build Z_r1 and Z_r2 (N × nLev) by extracting relevant columns
                    .zr1## = zero## (.nVal, .nLev)
                    .zr2## = zero## (.nVal, .nLev)
                    for .lv from 1 to .nLev
                        .zCol1 = .zStart + (.lv - 1) * .mEff + .row - 1
                        .zCol2 = .zStart + (.lv - 1) * .mEff + .col - 1
                        .col1# = rowSums# (part## (emlLMM.z##, 1, .nVal, .zCol1, .zCol1))
                        .col2# = rowSums# (part## (emlLMM.z##, 1, .nVal, .zCol2, .zCol2))
                        for .ii from 1 to .nVal
                            .zr1## [.ii, .lv] = .col1# [.ii]
                            .zr2## [.ii, .lv] = .col2# [.ii]
                        endfor
                    endfor
                    # SigmaG = Zr1 * Zr2' + Zr2 * Zr1' (or just Zr1*Zr1' if diagonal)
                    if .row = .col
                        .sg## = mul## (.zr1##, transpose## (.zr1##))
                    else
                        .sg## = mul## (.zr1##, transpose## (.zr2##)) +
                            ... mul## (.zr2##, transpose## (.zr1##))
                    endif
                    # R_r = X' V^{-1} SigmaG V^{-1} X = (V^{-1}X)' SigmaG (V^{-1}X)
                    # (Kenward & Roger 1997: R_r uses V^{-1}, not P)
                    .rMat'.rIdx'## = mul## (transpose## (.vInvX##),
                        ... mul## (.sg##, .vInvX##))
                    # OO_r = SigmaG * V^{-1} * X  (for QQ computation in PhiA)
                    .oo'.rIdx'## = mul## (.sg##, .vInvX##)
                    # Store P*SigmaG for information matrix (uses P, correct)
                    .pSg## = mul## (.pMat##, .sg##)
                    .pSgStore'.rIdx'## = .pSg##
                endfor
            endfor
        else
            # Uncorrelated: diagonal elements only
            for .diag from 1 to .mEff
                .rIdx = .rIdx + 1
                # Build Zr (N × nLev) by extracting the relevant columns
                .zr## = zero## (.nVal, .nLev)
                for .lv from 1 to .nLev
                    .zCol1 = .zStart + (.lv - 1) * .mEff + .diag - 1
                    .col# = rowSums# (part## (emlLMM.z##, 1, .nVal, .zCol1, .zCol1))
                    for .ii from 1 to .nVal
                        .zr## [.ii, .lv] = .col# [.ii]
                    endfor
                endfor
                # SigmaG = Zr * Zr' — single native mul## replaces N²×nLev triple loop
                .sg## = mul## (.zr##, transpose## (.zr##))
                # R_r = (V^{-1}X)' SigmaG (V^{-1}X)
                .rMat'.rIdx'## = mul## (transpose## (.vInvX##),
                    ... mul## (.sg##, .vInvX##))
                # OO_r = SigmaG * V^{-1} * X  (for QQ in PhiA)
                .oo'.rIdx'## = mul## (.sg##, .vInvX##)
                .pSg## = mul## (.pMat##, .sg##)
                .pSgStore'.rIdx'## = .pSg##
            endfor
        endif
    endfor

    # Last variance parameter: sigma^2 residual → SigmaG = I
    .rIdx = .rIdx + 1
    # R_r = (V^{-1}X)' I (V^{-1}X) = (V^{-1}X)' (V^{-1}X)
    .rMat'.rIdx'## = mul## (transpose## (.vInvX##), .vInvX##)
    # OO_r = I * V^{-1} * X = V^{-1} * X
    .oo'.rIdx'## = .vInvX##
    .pSg## = .pMat##
    .pSgStore'.rIdx'## = .pSg##

    # Step 6: Information matrix I[r,s] = 0.5 * trace(P SigmaG_r P SigmaG_s)
    .infoMat## = zero## (.nVarParsTotal, .nVarParsTotal)
    for .rr from 1 to .nVarParsTotal
        for .ss from .rr to .nVarParsTotal
            # trace(pSgStore_r * pSgStore_s) = sum(pSgStore_r .* pSgStore_s')
            .trVal = sum (.pSgStore'.rr'## * transpose## (.pSgStore'.ss'##))
            .infoMat## [.rr, .ss] = 0.5 * .trVal
            .infoMat## [.ss, .rr] = 0.5 * .trVal
        endfor
    endfor

    # Step 7: W = I^{-1} via native solve##
    .wEye## = zero## (.nVarParsTotal, .nVarParsTotal)
    for .ii from 1 to .nVarParsTotal
        .wEye## [.ii, .ii] = 1
    endfor
    .w## = solve## (.infoMat##, .wEye##)

    # Step 8: Phi_A — Kenward-Roger bias-corrected vcov
    # PhiA = A + 2 * A * [Σ_{r,s} W[r,s] * (QQ[r,s] - R_r A R_s)] * A
    # where QQ[r,s] = X'V^{-1}G_r V^{-1}G_s V^{-1}X = OO_r' * V^{-1} * OO_s
    # This follows pbkrtest::vcovAdj_internal exactly.
    # The term (QQ - R*A*R) = X'V^{-1}G_r P G_s V^{-1}X (where P is the
    # projection matrix) captures both the first-derivative contribution
    # (R_r A R_s) and the second-derivative contribution (QQ).
    .uu## = zero## (.pVal, .pVal)
    for .rr from 1 to .nVarParsTotal
        for .ss from 1 to .nVarParsTotal
            if abs (.w## [.rr, .ss]) > 1e-30
                # QQ[r,s] = OO_r' * V^{-1} * OO_s  (p×p)
                .qq## = mul## (transpose## (.oo'.rr'##),
                    ... mul## (.vInv##, .oo'.ss'##))
                # R_r A R_s  (p×p)
                .rAr## = mul## (.rMat'.rr'##,
                    ... mul## (.a##, .rMat'.ss'##))
                # Accumulate: W[r,s] * (QQ - R*A*R)
                .uu## = .uu## + .w## [.rr, .ss] * (.qq## - .rAr##)
            endif
        endfor
    endfor
    # GGAMMA = A * UU * A, PhiA = A + 2*GGAMMA
    .ggamma## = mul## (.a##, mul## (.uu##, .a##))
    .phiA## = .a## + 2 * .ggamma##

    .vcovAdj## = .phiA##

    # Step 9: KR df — using variance-parameterized derivatives
    # The R_r, information matrix, and W computed in steps 5-7 use the
    # VARIANCE parameterization (dV/dvariance_component), not Cholesky.
    # This is critical at the boundary (theta≈0) where Cholesky derivatives
    # vanish but variance derivatives remain non-zero.
    # Previous approach called @emlSatterthwaiteDF (Cholesky) as a base —
    # this gave residual df at the boundary because the Cholesky gradient
    # is zero there. Now we compute the Satterthwaite df directly from
    # the variance-parameterized data.

    # Base Satterthwaite df from variance-parameterized derivatives
    .dfSattVar# = zero# (.pVal)
    for .jj from 1 to .pVal
        .vVal = .a## [.jj, .jj]
        # Extract row j of A (A is symmetric)
        .aj# = columnSums# (part## (.a##, .jj, .jj, 1, .pVal))
        .gVec# = zero# (.nVarParsTotal)
        for .rr from 1 to .nVarParsTotal
            # gradient: A[j,:] * R_r * A[:,j]
            .gVec# [.rr] = inner (.aj#, mul# (.rMat'.rr'##, .aj#))
        endfor
        .quadForm = inner (.gVec#, mul# (.w##, .gVec#))
        if .quadForm > 0
            .dfSattVar# [.jj] = 2 * .vVal * .vVal / .quadForm
        else
            .dfSattVar# [.jj] = 1e6
        endif
        if .dfSattVar# [.jj] < 1
            .dfSattVar# [.jj] = 1
        endif
    endfor

    # Apply KR bias-correction adjustment
    # The KR df IS the Satterthwaite df computed from the expected Fisher
    # information in the variance parameterization. The PhiA adjustment
    # corrects the SE (stored in .vcovAdj), not the df.
    .dfKR# = zero# (.pVal)
    for .jj from 1 to .pVal
        .dfKR# [.jj] = .dfSattVar# [.jj]
        if .dfKR# [.jj] < 1
            .dfKR# [.jj] = 1
        endif
    endfor
    label END_KR
endproc

# ============================================================================
# @emlWaldCI
# Wald confidence intervals for fixed effects.
# Must be called after @emlLMM (uses stored results).
# Input: .level (e.g. 0.95 for 95% CI)
# Output: .lower# and .upper# (vectors, one per fixed effect)
# ============================================================================
procedure emlWaldCI: .level
    .pVal = emlLMM.nFixedCols
    .alpha = 1 - .level
    .lower# = zero# (.pVal)
    .upper# = zero# (.pVal)

    for .jj from 1 to .pVal
        .dfVal = emlLMM.dfBeta# [.jj]
        .tCrit = invStudentQ (.alpha / 2, .dfVal)
        .lower# [.jj] = emlLMM.beta# [.jj] - .tCrit * emlLMM.seBeta# [.jj]
        .upper# [.jj] = emlLMM.beta# [.jj] + .tCrit * emlLMM.seBeta# [.jj]
    endfor
endproc

# ============================================================================
# @emlProfileObjSig01
# Inner objective for multi-theta profile CI: profiling one sig01 component.
# Free variables: .x# = [remaining thetas..., sigma]
# Reads from emlProfileCI namespace:
#   .pinnedIdx    — which theta is pinned
#   .pinnedSgVal  — fixed sigma_group value for the pinned theta
#   .nTheta       — total number of thetas
#   .nObs         — number of observations
# theta_pinned = pinnedSgVal / sigma; full theta reconstructed.
# Returns .value = devfun2(all_thetas, sigma)
# ============================================================================
procedure emlProfileObjSig01: .x#
    .dFree = size (.x#)
    .sigma = .x# [.dFree]
    .dTheta = emlProfileCI.nTheta
    .nVal = emlProfileCI.nObs
    .twoPi = 2 * pi

    # Reconstruct full theta vector
    .fullTheta# = zero# (.dTheta)
    .freeIdx = 0
    for .ii from 1 to .dTheta
        if .ii = emlProfileCI.pinnedIdx
            .fullTheta# [.ii] = emlProfileCI.pinnedSgVal / .sigma
        else
            .freeIdx = .freeIdx + 1
            .fullTheta# [.ii] = .x# [.freeIdx]
        endif
    endfor

    @emlProfiledDeviance: .fullTheta#
    if emlProfiledDeviance.value >= 1e29
        .value = 1e30
    else
        .value = emlProfiledDeviance.ldL2
            ... + emlProfiledDeviance.pwrss / (.sigma * .sigma)
            ... + .nVal * ln (.twoPi * .sigma * .sigma)
    endif
endproc

# ============================================================================
# @emlProfileObjSigma
# Inner objective for multi-theta profile CI: profiling sigma.
# Free variables: .x# = all thetas
# Reads from emlProfileCI namespace:
#   .fixedSigma  — the sigma value being profiled
#   .nObs        — number of observations
# Returns .value = devfun2(thetas, fixedSigma)
# ============================================================================
procedure emlProfileObjSigma: .x#
    .nVal = emlProfileCI.nObs
    .sigma = emlProfileCI.fixedSigma
    .twoPi = 2 * pi

    @emlProfiledDeviance: .x#
    if emlProfiledDeviance.value >= 1e29
        .value = 1e30
    else
        .value = emlProfiledDeviance.ldL2
            ... + emlProfiledDeviance.pwrss / (.sigma * .sigma)
            ... + .nVal * ln (.twoPi * .sigma * .sigma)
    endif
endproc

# ============================================================================
# @emlProfileObjSv
# Inner objective for Sv-scale profile CI (correlated 2×2 RE block).
# Free variables: .x# = [remaining Sv params..., sigma]
# Reads from emlProfileCI namespace:
#   .pinnedIdx    — which Sv param is pinned (1..nTheta)
#   .pinnedSvVal  — fixed Sv value (SD or correlation)
#   .nTheta       — total number of Sv params (= nTheta = 3 for 2×2)
#   .nObs         — number of observations
# Sv = [sd1, rho, sd2] for 2×2 block.
# Converts Sv → theta via: theta1=sd1/sigma, theta2=rho*sd2/sigma,
#   theta3=sd2*sqrt(1-rho^2)/sigma. Then evaluates devfun2.
# Returns .value = devfun2(theta, sigma)
# ============================================================================
procedure emlProfileObjSv: .x#
    .dFree = size (.x#)
    .sigma = .x# [.dFree]
    .dTheta = emlProfileCI.nTheta
    .nVal = emlProfileCI.nObs
    .twoPi = 2 * pi

    # Reconstruct full Sv vector
    .fullSv# = zero# (.dTheta)
    .freeIdx = 0
    for .ii from 1 to .dTheta
        if .ii = emlProfileCI.pinnedIdx
            .fullSv# [.ii] = emlProfileCI.pinnedSvVal
        else
            .freeIdx = .freeIdx + 1
            .fullSv# [.ii] = .x# [.freeIdx]
        endif
    endfor

    # Convert Sv → theta (2×2 block)
    .sd1 = .fullSv# [1]
    .rho = .fullSv# [2]
    .sd2 = .fullSv# [3]
    .rhoSq = .rho * .rho
    if .rhoSq >= 0.9999 or .sd1 <= 0 or .sd2 <= 0 or .sigma <= 0
        .value = 1e30
    else
        .fullTheta# = zero# (3)
        .fullTheta# [1] = .sd1 / .sigma
        .fullTheta# [2] = .rho * .sd2 / .sigma
        .fullTheta# [3] = .sd2 * sqrt (1 - .rhoSq) / .sigma

        @emlProfiledDeviance: .fullTheta#
        if emlProfiledDeviance.value >= 1e29
            .value = 1e30
        else
            .value = emlProfiledDeviance.ldL2
                ... + emlProfiledDeviance.pwrss / (.sigma * .sigma)
                ... + .nVal * ln (.twoPi * .sigma * .sigma)
        endif
    endif
endproc

# ============================================================================
# @emlProfileCI
# Profile likelihood confidence intervals for the VARIANCE PARAMETERS.
# Input: .level (e.g. 0.95)
# Output: .lowerBeta#, .upperBeta# (fixed effects — see note)
#         .lowerSig01# (RE sd / sigma ratios), .upperSig01#
#         .lowerSigma, .upperSigma (residual SD)
# NOTE (L4): profiling here is scoped to the variance components (RE SD/
# correlation and residual sigma). The fixed-effect intervals .lowerBeta#/
# .upperBeta# are t-based WALD intervals (beta +/- t(Satterthwaite df)*se),
# NOT profiled. They are correct Wald intervals but will differ from R's
# confint(method="profile") on the fixed effects, which profiles beta too.
# This is an intentional scope limit, not a bug.
# For d=1 (random intercept): uses 1D golden section.
# For d>1 (random slope etc.): uses Nelder-Mead inner optimization.
#   Correlated 2×2 blocks: Sv-scale profiling (SD/correlation).
#   Other structures: Cholesky-scale profiling.
# ============================================================================
procedure emlProfileCI: .level
    .pVal = emlLMM.nFixedCols
    .dVal = size (emlLMM.thetaOpt#)
    .nVal = emlLMM.nObs
    .cutoff = invChiSquareQ (1 - .level, 1)
    .twoPi = 2 * pi

    # Profile CIs use ML deviance with sigma free (Bates et al., 2015).
    # devfun2(sig01, sigma) = ldL2(sig01/sigma) + pwrss(sig01/sigma)/sigma^2
    #                         + n*log(2*pi*sigma^2)
    # NOTE (empirical, 2026-07-22): forcing ML profiling here — even when the
    # model was fit by REML — reproduces R's confint(method="profile") on the
    # REML fit to <=1e-6 on the random-slope reference. Because sigma is
    # profiled free in both criteria, the variance-component profile shape is
    # effectively criterion-independent, so this is NOT the anticonservative
    # divergence the static review anticipated. Do not "restore" a REML
    # criterion here expecting different CIs; verified equivalent.
    .savedUseREML = emlLMM.useREML
    emlLMM.useREML = 0

    # Multi-theta models (d>1) use a different profiling strategy
    # with multi-dimensional inner optimization. Single-theta (d=1)
    # uses the original 1D golden section approach.
    if .dVal > 1
        goto PROFILE_MULTI_THETA
    endif

    # Helper: evaluate full ML deviance at (sig01, sigma)
    # theta = sig01/sigma; evaluates @emlProfiledDeviance at theta
    # then computes: ldL2 + pwrss/sigma^2 + n*log(2*pi*sigma^2)

    # Step 1: Find ML optimum via golden section over theta
    # (at profiled sigma, devfun2 = profiled ML deviance)
    .thetaML# = emlLMM.thetaOpt#
    .phi = (1 + sqrt (5)) / 2
    .resphi = 2 - .phi
    for .kk from 1 to .dVal
        .aGS = max (emlRandomEffectsZ.thetaLower# [.kk], 0.001)
        .bGS = .thetaML# [.kk] * 3
        .xGS1 = .aGS + .resphi * (.bGS - .aGS)
        .xGS2 = .bGS - .resphi * (.bGS - .aGS)
        .thetaML# [.kk] = .xGS1
        @emlProfiledDeviance: .thetaML#
        .fGS1 = emlProfiledDeviance.value
        .thetaML# [.kk] = .xGS2
        @emlProfiledDeviance: .thetaML#
        .fGS2 = emlProfiledDeviance.value
        for .gsIter from 1 to 100
            if abs (.bGS - .aGS) < 1e-8
                goto GS_DONE
            endif
            if .fGS1 < .fGS2
                .bGS = .xGS2
                .xGS2 = .xGS1
                .fGS2 = .fGS1
                .xGS1 = .aGS + .resphi * (.bGS - .aGS)
                .thetaML# [.kk] = .xGS1
                @emlProfiledDeviance: .thetaML#
                .fGS1 = emlProfiledDeviance.value
            else
                .aGS = .xGS1
                .xGS1 = .xGS2
                .fGS1 = .fGS2
                .xGS2 = .bGS - .resphi * (.bGS - .aGS)
                .thetaML# [.kk] = .xGS2
                @emlProfiledDeviance: .thetaML#
                .fGS2 = emlProfiledDeviance.value
            endif
        endfor
        label GS_DONE
        .thetaML# [.kk] = (.aGS + .bGS) / 2
    endfor

    @emlProfiledDeviance: .thetaML#
    .sigmaML = sqrt (emlProfiledDeviance.pwrss / .nVal)
    # Full ML deviance at optimum (with profiled sigma, equals profiled ML dev)
    .mlDevOpt = emlProfiledDeviance.ldL2 + .nVal + .nVal * ln (.twoPi * emlProfiledDeviance.pwrss / .nVal)

    # Step 2: Profile on sigma_group scale with proper sigma optimization.
    # For each sigma_group candidate, do golden section over sigma to minimize
    # devfun2(sig01, sigma) = ldL2(sig01/sigma) + pwrss(sig01/sigma)/sigma^2
    #                         + n*log(2*pi*sigma^2)
    .lowerSig01# = zero# (.dVal)
    .upperSig01# = zero# (.dVal)

    for .kk from 1 to .dVal
        .sgOpt = .thetaML# [.kk] * .sigmaML
        .step = max (.sgOpt * 0.1, 0.05)

        # --- Lower bound bracket ---
        .sgLo = .sgOpt
        .found = 0
        .iter = 0
        .wsSig = .sigmaML
        repeat
            .sgLo = .sgLo - .step
            if .sgLo < 0.001
                .sgLo = 0.001
                .found = -1
            endif
            # Optimize sigma at this sig01 via GS (warm-started)
            .sigA = .wsSig * 0.5
            .sigB = .wsSig * 2
            .sigX1 = .sigA + .resphi * (.sigB - .sigA)
            .sigX2 = .sigB - .resphi * (.sigB - .sigA)
            # Eval at sigX1
            .thetaVec# = .thetaML#
            .thetaVec# [.kk] = .sgLo / .sigX1
            @emlProfiledDeviance: .thetaVec#
            .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX1 * .sigX1) + .nVal * ln (.twoPi * .sigX1 * .sigX1)
            # Eval at sigX2
            .thetaVec# [.kk] = .sgLo / .sigX2
            @emlProfiledDeviance: .thetaVec#
            .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX2 * .sigX2) + .nVal * ln (.twoPi * .sigX2 * .sigX2)
            for .gsS from 1 to 25
                if abs (.sigB - .sigA) < 1e-8
                    goto SIG_LO_DONE
                endif
                if .fs1 < .fs2
                    .sigB = .sigX2
                    .sigX2 = .sigX1
                    .fs2 = .fs1
                    .sigX1 = .sigA + .resphi * (.sigB - .sigA)
                    .thetaVec# [.kk] = .sgLo / .sigX1
                    @emlProfiledDeviance: .thetaVec#
                    .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX1 * .sigX1) + .nVal * ln (.twoPi * .sigX1 * .sigX1)
                else
                    .sigA = .sigX1
                    .sigX1 = .sigX2
                    .fs1 = .fs2
                    .sigX2 = .sigB - .resphi * (.sigB - .sigA)
                    .thetaVec# [.kk] = .sgLo / .sigX2
                    @emlProfiledDeviance: .thetaVec#
                    .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX2 * .sigX2) + .nVal * ln (.twoPi * .sigX2 * .sigX2)
                endif
            endfor
            label SIG_LO_DONE
            .wsSig = (.sigA + .sigB) / 2
            .sigmaAtSg = .wsSig
            .thetaVec# [.kk] = .sgLo / .sigmaAtSg
            @emlProfiledDeviance: .thetaVec#
            .mlDev = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigmaAtSg * .sigmaAtSg) + .nVal * ln (.twoPi * .sigmaAtSg * .sigmaAtSg)
            .iter = .iter + 1
            if .mlDev - .mlDevOpt >= .cutoff
                .found = 1
            endif
        until .found <> 0 or .iter > 50

        if .found = 1
            .bsHi = .sgOpt
            .bsLo = .sgLo
            for .bisect from 1 to 30
                .bsMid = (.bsHi + .bsLo) / 2
                # GS over sigma at bsMid
                .sigA = .wsSig * 0.5
                .sigB = .wsSig * 2
                .sigX1 = .sigA + .resphi * (.sigB - .sigA)
                .sigX2 = .sigB - .resphi * (.sigB - .sigA)
                .thetaVec# = .thetaML#
                .thetaVec# [.kk] = .bsMid / .sigX1
                @emlProfiledDeviance: .thetaVec#
                .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX1 * .sigX1) + .nVal * ln (.twoPi * .sigX1 * .sigX1)
                .thetaVec# [.kk] = .bsMid / .sigX2
                @emlProfiledDeviance: .thetaVec#
                .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX2 * .sigX2) + .nVal * ln (.twoPi * .sigX2 * .sigX2)
                for .gsS from 1 to 20
                    if abs (.sigB - .sigA) < 1e-6
                        goto SIG_BS_LO_DONE
                    endif
                    if .fs1 < .fs2
                        .sigB = .sigX2
                        .sigX2 = .sigX1
                        .fs2 = .fs1
                        .sigX1 = .sigA + .resphi * (.sigB - .sigA)
                        .thetaVec# [.kk] = .bsMid / .sigX1
                        @emlProfiledDeviance: .thetaVec#
                        .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX1 * .sigX1) + .nVal * ln (.twoPi * .sigX1 * .sigX1)
                    else
                        .sigA = .sigX1
                        .sigX1 = .sigX2
                        .fs1 = .fs2
                        .sigX2 = .sigB - .resphi * (.sigB - .sigA)
                        .thetaVec# [.kk] = .bsMid / .sigX2
                        @emlProfiledDeviance: .thetaVec#
                        .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX2 * .sigX2) + .nVal * ln (.twoPi * .sigX2 * .sigX2)
                    endif
                endfor
                label SIG_BS_LO_DONE
                .sigmaAtSg = (.sigA + .sigB) / 2
                .thetaVec# [.kk] = .bsMid / .sigmaAtSg
                @emlProfiledDeviance: .thetaVec#
                .mlDev = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigmaAtSg * .sigmaAtSg) + .nVal * ln (.twoPi * .sigmaAtSg * .sigmaAtSg)
                if .mlDev - .mlDevOpt < .cutoff
                    .bsHi = .bsMid
                else
                    .bsLo = .bsMid
                endif
            endfor
            .lowerSig01# [.kk] = (.bsHi + .bsLo) / 2
        else
            .lowerSig01# [.kk] = emlRandomEffectsZ.thetaLower# [.kk]
        endif

        # --- Upper bound ---
        .sgHi = .sgOpt
        .wsSig = .sigmaML
        .found = 0
        .iter = 0
        repeat
            .sgHi = .sgHi + .step
            .sigA = .wsSig * 0.5
            .sigB = .wsSig * 2
            .sigX1 = .sigA + .resphi * (.sigB - .sigA)
            .sigX2 = .sigB - .resphi * (.sigB - .sigA)
            .thetaVec# = .thetaML#
            .thetaVec# [.kk] = .sgHi / .sigX1
            @emlProfiledDeviance: .thetaVec#
            .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX1 * .sigX1) + .nVal * ln (.twoPi * .sigX1 * .sigX1)
            .thetaVec# [.kk] = .sgHi / .sigX2
            @emlProfiledDeviance: .thetaVec#
            .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX2 * .sigX2) + .nVal * ln (.twoPi * .sigX2 * .sigX2)
            for .gsS from 1 to 25
                if abs (.sigB - .sigA) < 1e-8
                    goto SIG_HI_DONE
                endif
                if .fs1 < .fs2
                    .sigB = .sigX2
                    .sigX2 = .sigX1
                    .fs2 = .fs1
                    .sigX1 = .sigA + .resphi * (.sigB - .sigA)
                    .thetaVec# [.kk] = .sgHi / .sigX1
                    @emlProfiledDeviance: .thetaVec#
                    .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX1 * .sigX1) + .nVal * ln (.twoPi * .sigX1 * .sigX1)
                else
                    .sigA = .sigX1
                    .sigX1 = .sigX2
                    .fs1 = .fs2
                    .sigX2 = .sigB - .resphi * (.sigB - .sigA)
                    .thetaVec# [.kk] = .sgHi / .sigX2
                    @emlProfiledDeviance: .thetaVec#
                    .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX2 * .sigX2) + .nVal * ln (.twoPi * .sigX2 * .sigX2)
                endif
            endfor
            label SIG_HI_DONE
            .wsSig = (.sigA + .sigB) / 2
            .sigmaAtSg = .wsSig
            .thetaVec# [.kk] = .sgHi / .sigmaAtSg
            @emlProfiledDeviance: .thetaVec#
            .mlDev = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigmaAtSg * .sigmaAtSg) + .nVal * ln (.twoPi * .sigmaAtSg * .sigmaAtSg)
            .iter = .iter + 1
            if .mlDev - .mlDevOpt >= .cutoff
                .found = 1
            endif
        until .found = 1 or .iter > 50

        if .found = 1
            .bsLo = .sgOpt
            .bsHi = .sgHi
            for .bisect from 1 to 30
                .bsMid = (.bsHi + .bsLo) / 2
                .sigA = .wsSig * 0.5
                .sigB = .wsSig * 2
                .sigX1 = .sigA + .resphi * (.sigB - .sigA)
                .sigX2 = .sigB - .resphi * (.sigB - .sigA)
                .thetaVec# = .thetaML#
                .thetaVec# [.kk] = .bsMid / .sigX1
                @emlProfiledDeviance: .thetaVec#
                .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX1 * .sigX1) + .nVal * ln (.twoPi * .sigX1 * .sigX1)
                .thetaVec# [.kk] = .bsMid / .sigX2
                @emlProfiledDeviance: .thetaVec#
                .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX2 * .sigX2) + .nVal * ln (.twoPi * .sigX2 * .sigX2)
                for .gsS from 1 to 20
                    if abs (.sigB - .sigA) < 1e-6
                        goto SIG_BS_HI_DONE
                    endif
                    if .fs1 < .fs2
                        .sigB = .sigX2
                        .sigX2 = .sigX1
                        .fs2 = .fs1
                        .sigX1 = .sigA + .resphi * (.sigB - .sigA)
                        .thetaVec# [.kk] = .bsMid / .sigX1
                        @emlProfiledDeviance: .thetaVec#
                        .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX1 * .sigX1) + .nVal * ln (.twoPi * .sigX1 * .sigX1)
                    else
                        .sigA = .sigX1
                        .sigX1 = .sigX2
                        .fs1 = .fs2
                        .sigX2 = .sigB - .resphi * (.sigB - .sigA)
                        .thetaVec# [.kk] = .bsMid / .sigX2
                        @emlProfiledDeviance: .thetaVec#
                        .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigX2 * .sigX2) + .nVal * ln (.twoPi * .sigX2 * .sigX2)
                    endif
                endfor
                label SIG_BS_HI_DONE
                .sigmaAtSg = (.sigA + .sigB) / 2
                .thetaVec# [.kk] = .bsMid / .sigmaAtSg
                @emlProfiledDeviance: .thetaVec#
                .mlDev = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigmaAtSg * .sigmaAtSg) + .nVal * ln (.twoPi * .sigmaAtSg * .sigmaAtSg)
                if .mlDev - .mlDevOpt < .cutoff
                    .bsLo = .bsMid
                else
                    .bsHi = .bsMid
                endif
            endfor
            .upperSig01# [.kk] = (.bsHi + .bsLo) / 2
        else
            .upperSig01# [.kk] = undefined
        endif
    endfor

    emlLMM.useREML = .savedUseREML

    # Sigma CI via profile on devfun2: fix sigma, optimize sig01
    .sigStep = max (.sigmaML * 0.05, 0.01)
    # --- Sigma lower bound ---
    .sigProbe = .sigmaML
    .foundSigLo = 0
    .wsS01 = .thetaML# [1] * .sigmaML
    .sigIter = 0
    repeat
        .sigProbe = .sigProbe - .sigStep
        if .sigProbe < 0.01
            .sigProbe = 0.01
            .foundSigLo = -1
        endif
        # Optimize sig01 at this sigma via GS
        .s01A = max (0.001, .wsS01 * 0.5)
        .s01B = .wsS01 * 2
        if .s01B < 0.1
            .s01B = 10
        endif
        .s01X1 = .s01A + .resphi * (.s01B - .s01A)
        .s01X2 = .s01B - .resphi * (.s01B - .s01A)
        .thetaVec# = .thetaML#
        .thetaVec# [1] = .s01X1 / .sigProbe
        @emlProfiledDeviance: .thetaVec#
        .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigProbe * .sigProbe) + .nVal * ln (.twoPi * .sigProbe * .sigProbe)
        .thetaVec# [1] = .s01X2 / .sigProbe
        @emlProfiledDeviance: .thetaVec#
        .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigProbe * .sigProbe) + .nVal * ln (.twoPi * .sigProbe * .sigProbe)
        for .gsI from 1 to 25
            if abs (.s01B - .s01A) < 1e-6
                goto SIG_PROF_LO_GS
            endif
            if .fs1 < .fs2
                .s01B = .s01X2
                .s01X2 = .s01X1
                .fs2 = .fs1
                .s01X1 = .s01A + .resphi * (.s01B - .s01A)
                .thetaVec# [1] = .s01X1 / .sigProbe
                @emlProfiledDeviance: .thetaVec#
                .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigProbe * .sigProbe) + .nVal * ln (.twoPi * .sigProbe * .sigProbe)
            else
                .s01A = .s01X1
                .s01X1 = .s01X2
                .fs1 = .fs2
                .s01X2 = .s01B - .resphi * (.s01B - .s01A)
                .thetaVec# [1] = .s01X2 / .sigProbe
                @emlProfiledDeviance: .thetaVec#
                .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigProbe * .sigProbe) + .nVal * ln (.twoPi * .sigProbe * .sigProbe)
            endif
        endfor
        label SIG_PROF_LO_GS
        .wsS01 = (.s01A + .s01B) / 2
        .dd2Min = min (.fs1, .fs2)
        .sigIter = .sigIter + 1
        if .dd2Min - .mlDevOpt >= .cutoff
            .foundSigLo = 1
        endif
    until .foundSigLo <> 0 or .sigIter > 60

    if .foundSigLo = 1
        .bsSigHi = .sigmaML
        .bsSigLo = .sigProbe
        for .bsI from 1 to 20
            .bsSigMid = (.bsSigHi + .bsSigLo) / 2
            .s01A = max (0.001, .wsS01 * 0.5)
            .s01B = .wsS01 * 2
            if .s01B < 0.1
                .s01B = 10
            endif
            .s01X1 = .s01A + .resphi * (.s01B - .s01A)
            .s01X2 = .s01B - .resphi * (.s01B - .s01A)
            .thetaVec# [1] = .s01X1 / .bsSigMid
            @emlProfiledDeviance: .thetaVec#
            .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.bsSigMid * .bsSigMid) + .nVal * ln (.twoPi * .bsSigMid * .bsSigMid)
            .thetaVec# [1] = .s01X2 / .bsSigMid
            @emlProfiledDeviance: .thetaVec#
            .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.bsSigMid * .bsSigMid) + .nVal * ln (.twoPi * .bsSigMid * .bsSigMid)
            for .gsI from 1 to 20
                if abs (.s01B - .s01A) < 1e-6
                    goto SIG_PROF_LO_BS
                endif
                if .fs1 < .fs2
                    .s01B = .s01X2
                    .s01X2 = .s01X1
                    .fs2 = .fs1
                    .s01X1 = .s01A + .resphi * (.s01B - .s01A)
                    .thetaVec# [1] = .s01X1 / .bsSigMid
                    @emlProfiledDeviance: .thetaVec#
                    .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.bsSigMid * .bsSigMid) + .nVal * ln (.twoPi * .bsSigMid * .bsSigMid)
                else
                    .s01A = .s01X1
                    .s01X1 = .s01X2
                    .fs1 = .fs2
                    .s01X2 = .s01B - .resphi * (.s01B - .s01A)
                    .thetaVec# [1] = .s01X2 / .bsSigMid
                    @emlProfiledDeviance: .thetaVec#
                    .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.bsSigMid * .bsSigMid) + .nVal * ln (.twoPi * .bsSigMid * .bsSigMid)
                endif
            endfor
            label SIG_PROF_LO_BS
            .wsS01 = (.s01A + .s01B) / 2
            .dd2Min = min (.fs1, .fs2)
            if .dd2Min - .mlDevOpt < .cutoff
                .bsSigHi = .bsSigMid
            else
                .bsSigLo = .bsSigMid
            endif
        endfor
        .lowerSigma = (.bsSigHi + .bsSigLo) / 2
    else
        .lowerSigma = 0
    endif

    # --- Sigma upper bound ---
    .sigProbe = .sigmaML
    .foundSigHi = 0
    .wsS01 = .thetaML# [1] * .sigmaML
    .sigIter = 0
    repeat
        .sigProbe = .sigProbe + .sigStep
        .s01A = max (0.001, .wsS01 * 0.5)
        .s01B = .wsS01 * 2
        if .s01B < 0.1
            .s01B = 10
        endif
        .s01X1 = .s01A + .resphi * (.s01B - .s01A)
        .s01X2 = .s01B - .resphi * (.s01B - .s01A)
        .thetaVec# = .thetaML#
        .thetaVec# [1] = .s01X1 / .sigProbe
        @emlProfiledDeviance: .thetaVec#
        .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigProbe * .sigProbe) + .nVal * ln (.twoPi * .sigProbe * .sigProbe)
        .thetaVec# [1] = .s01X2 / .sigProbe
        @emlProfiledDeviance: .thetaVec#
        .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigProbe * .sigProbe) + .nVal * ln (.twoPi * .sigProbe * .sigProbe)
        for .gsI from 1 to 25
            if abs (.s01B - .s01A) < 1e-6
                goto SIG_PROF_HI_GS
            endif
            if .fs1 < .fs2
                .s01B = .s01X2
                .s01X2 = .s01X1
                .fs2 = .fs1
                .s01X1 = .s01A + .resphi * (.s01B - .s01A)
                .thetaVec# [1] = .s01X1 / .sigProbe
                @emlProfiledDeviance: .thetaVec#
                .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigProbe * .sigProbe) + .nVal * ln (.twoPi * .sigProbe * .sigProbe)
            else
                .s01A = .s01X1
                .s01X1 = .s01X2
                .fs1 = .fs2
                .s01X2 = .s01B - .resphi * (.s01B - .s01A)
                .thetaVec# [1] = .s01X2 / .sigProbe
                @emlProfiledDeviance: .thetaVec#
                .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.sigProbe * .sigProbe) + .nVal * ln (.twoPi * .sigProbe * .sigProbe)
            endif
        endfor
        label SIG_PROF_HI_GS
        .wsS01 = (.s01A + .s01B) / 2
        .dd2Min = min (.fs1, .fs2)
        .sigIter = .sigIter + 1
        if .dd2Min - .mlDevOpt >= .cutoff
            .foundSigHi = 1
        endif
    until .foundSigHi = 1 or .sigIter > 60

    if .foundSigHi = 1
        .bsSigLo = .sigmaML
        .bsSigHi = .sigProbe
        for .bsI from 1 to 20
            .bsSigMid = (.bsSigHi + .bsSigLo) / 2
            .s01A = max (0.001, .wsS01 * 0.5)
            .s01B = .wsS01 * 2
            if .s01B < 0.1
                .s01B = 10
            endif
            .s01X1 = .s01A + .resphi * (.s01B - .s01A)
            .s01X2 = .s01B - .resphi * (.s01B - .s01A)
            .thetaVec# [1] = .s01X1 / .bsSigMid
            @emlProfiledDeviance: .thetaVec#
            .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.bsSigMid * .bsSigMid) + .nVal * ln (.twoPi * .bsSigMid * .bsSigMid)
            .thetaVec# [1] = .s01X2 / .bsSigMid
            @emlProfiledDeviance: .thetaVec#
            .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.bsSigMid * .bsSigMid) + .nVal * ln (.twoPi * .bsSigMid * .bsSigMid)
            for .gsI from 1 to 20
                if abs (.s01B - .s01A) < 1e-6
                    goto SIG_PROF_HI_BS
                endif
                if .fs1 < .fs2
                    .s01B = .s01X2
                    .s01X2 = .s01X1
                    .fs2 = .fs1
                    .s01X1 = .s01A + .resphi * (.s01B - .s01A)
                    .thetaVec# [1] = .s01X1 / .bsSigMid
                    @emlProfiledDeviance: .thetaVec#
                    .fs1 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.bsSigMid * .bsSigMid) + .nVal * ln (.twoPi * .bsSigMid * .bsSigMid)
                else
                    .s01A = .s01X1
                    .s01X1 = .s01X2
                    .fs1 = .fs2
                    .s01X2 = .s01B - .resphi * (.s01B - .s01A)
                    .thetaVec# [1] = .s01X2 / .bsSigMid
                    @emlProfiledDeviance: .thetaVec#
                    .fs2 = emlProfiledDeviance.ldL2 + emlProfiledDeviance.pwrss / (.bsSigMid * .bsSigMid) + .nVal * ln (.twoPi * .bsSigMid * .bsSigMid)
                endif
            endfor
            label SIG_PROF_HI_BS
            .wsS01 = (.s01A + .s01B) / 2
            .dd2Min = min (.fs1, .fs2)
            if .dd2Min - .mlDevOpt < .cutoff
                .bsSigLo = .bsSigMid
            else
                .bsSigHi = .bsSigMid
            endif
        endfor
        .upperSigma = (.bsSigHi + .bsSigLo) / 2
    else
        .upperSigma = undefined
    endif

    goto PROFILE_BETA_CI

    # ================================================================
    # MULTI-THETA PATH (d > 1)
    # Uses Nelder-Mead inner optimization over (free_thetas, sigma)
    # when profiling each sig01 component, and over all thetas when
    # profiling sigma. Outer loop: bracket + bisect (same as d=1).
    # ================================================================
    label PROFILE_MULTI_THETA

    # Communication variables for inner objectives
    .pinnedIdx = 0
    .pinnedSgVal = 0
    .pinnedSvVal = 0
    .fixedSigma = 0
    .nTheta = .dVal
    .nObs = .nVal

    # Step 1 (multi-theta): ML optimum via BOBYQA
    .thetaML# = emlLMM.thetaOpt#
    .thetaUpper# = zero# (.dVal)
    for .ii from 1 to .dVal
        .thetaUpper# [.ii] = 1e30
    endfor
    @emlBOBYQA: "emlProfiledDeviance", .thetaML#,
        ... emlRandomEffectsZ.thetaLower#, .thetaUpper#,
        ... 0.1, 1e-6, 2000, 0
    .thetaML# = emlBOBYQA.xOpt#

    @emlProfiledDeviance: .thetaML#
    .sigmaML = sqrt (emlProfiledDeviance.pwrss / .nVal)
    .mlDevOpt = emlProfiledDeviance.ldL2 + .nVal
        ... + .nVal * ln (.twoPi * emlProfiledDeviance.pwrss / .nVal)

    # Step 2 (multi-theta): sig01 CIs on the Sv (SD/correlation) scale
    # For correlated 2×2 blocks, R's lme4 profiles on the Sv scale
    # (standard deviations + correlations) via Cv_to_Sv / Sv_to_Cv.
    # This gives interpretable CIs and matches R's confint(method="profile").
    #
    # Sv parameterization for 2×2 block [theta1, theta2, theta3]:
    #   sv[1] = sd1 = theta[1] * sigma
    #   sv[2] = rho = theta[2] / sqrt(theta[2]^2 + theta[3]^2)
    #   sv[3] = sd2 = sqrt(theta[2]^2 + theta[3]^2) * sigma
    #
    # Inverse (Sv → theta):
    #   theta[1] = sd1 / sigma
    #   theta[2] = rho * sd2 / sigma
    #   theta[3] = sd2 * sqrt(1 - rho^2) / sigma

    .lowerSig01# = zero# (.dVal)
    .upperSig01# = zero# (.dVal)

    # Check for single correlated 2×2 block (the common case)
    .useSvScale = 0
    if emlRandomEffectsZ.nTerms = 1
        .termIdx = 1
        if emlRandomEffectsZ.termCorrelated'.termIdx' = 1
            if emlRandomEffectsZ.termNEffects'.termIdx' = 2
                .useSvScale = 1
            endif
        endif
    endif

    if .useSvScale
        # Convert ML theta to Sv
        .norm23 = sqrt (.thetaML# [2] * .thetaML# [2]
            ... + .thetaML# [3] * .thetaML# [3])
        .svOpt# = zero# (3)
        .svOpt# [1] = .thetaML# [1] * .sigmaML
        if .norm23 > 1e-15
            .svOpt# [2] = .thetaML# [2] / .norm23
        else
            .svOpt# [2] = 0
        endif
        .svOpt# [3] = .norm23 * .sigmaML

        for .kk from 1 to .dVal
            .svVal = .svOpt# [.kk]
            .pinnedIdx = .kk

            # Step size and bounds depend on parameter type
            if .kk = 2
                # Correlation: bounded (-1, 1)
                .step = 0.05
                .svFloor = -0.999
                .svCeiling = 0.999
            else
                # Standard deviation: bounded (0, +inf)
                .step = max (.svVal * 0.1, 0.02)
                .svFloor = 0.001
                .svCeiling = 1e30
            endif

            # Build initial inner point and bounds:
            # Free vars = [other Sv params (excl kk), sigma]
            .innerInit# = zero# (.dVal)
            .innerLower# = zero# (.dVal)
            .innerUpper# = zero# (.dVal)
            .freeIdx = 0
            for .ii from 1 to .dVal
                if .ii <> .kk
                    .freeIdx = .freeIdx + 1
                    .innerInit# [.freeIdx] = .svOpt# [.ii]
                    if .ii = 2
                        .innerLower# [.freeIdx] = -0.999
                        .innerUpper# [.freeIdx] = 0.999
                    else
                        .innerLower# [.freeIdx] = 0.001
                        .innerUpper# [.freeIdx] = 1e30
                    endif
                endif
            endfor
            .innerInit# [.dVal] = .sigmaML
            .innerLower# [.dVal] = 0.001
            .innerUpper# [.dVal] = 1e30

            # --- Lower bound bracket ---
            .svLo = .svVal
            .found = 0
            .iter = 0
            .wsPoint# = .innerInit#
            repeat
                .svLo = .svLo - .step
                if .svLo < .svFloor
                    .svLo = .svFloor
                    .found = -1
                endif
                .pinnedSvVal = .svLo
                @emlNelderMead: "emlProfileObjSv", .wsPoint#,
                    ... .innerLower#, .innerUpper#, 1e-6, 300
                .wsPoint# = emlNelderMead.xOpt#
                .mlDev = emlNelderMead.fOpt
                .iter = .iter + 1
                if .mlDev - .mlDevOpt >= .cutoff
                    .found = 1
                endif
            until .found <> 0 or .iter > 50

            if .found = 1
                .bsHi = .svVal
                .bsLo = .svLo
                for .bisect from 1 to 15
                    .bsMid = (.bsHi + .bsLo) / 2
                    .pinnedSvVal = .bsMid
                    @emlNelderMead: "emlProfileObjSv", .wsPoint#,
                        ... .innerLower#, .innerUpper#, 1e-6, 200
                    .wsPoint# = emlNelderMead.xOpt#
                    .mlDev = emlNelderMead.fOpt
                    if .mlDev - .mlDevOpt < .cutoff
                        .bsHi = .bsMid
                    else
                        .bsLo = .bsMid
                    endif
                endfor
                .lowerSig01# [.kk] = (.bsHi + .bsLo) / 2
            else
                if .kk = 2
                    # Correlation: lower bound is -1
                    .lowerSig01# [.kk] = -1
                else
                    # SD: lower bound is 0
                    .lowerSig01# [.kk] = 0
                endif
            endif

            # --- Upper bound bracket ---
            .svHi = .svVal
            .wsPoint# = .innerInit#
            .found = 0
            .iter = 0
            repeat
                .svHi = .svHi + .step
                if .svHi > .svCeiling
                    .svHi = .svCeiling
                    .found = -1
                endif
                .pinnedSvVal = .svHi
                @emlNelderMead: "emlProfileObjSv", .wsPoint#,
                    ... .innerLower#, .innerUpper#, 1e-6, 300
                .wsPoint# = emlNelderMead.xOpt#
                .mlDev = emlNelderMead.fOpt
                .iter = .iter + 1
                if .mlDev - .mlDevOpt >= .cutoff
                    .found = 1
                endif
            until .found <> 0 or .iter > 50

            if .found = 1
                .bsLo = .svVal
                .bsHi = .svHi
                for .bisect from 1 to 15
                    .bsMid = (.bsHi + .bsLo) / 2
                    .pinnedSvVal = .bsMid
                    @emlNelderMead: "emlProfileObjSv", .wsPoint#,
                        ... .innerLower#, .innerUpper#, 1e-6, 200
                    .wsPoint# = emlNelderMead.xOpt#
                    .mlDev = emlNelderMead.fOpt
                    if .mlDev - .mlDevOpt < .cutoff
                        .bsLo = .bsMid
                    else
                        .bsHi = .bsMid
                    endif
                endfor
                .upperSig01# [.kk] = (.bsHi + .bsLo) / 2
            else
                .upperSig01# [.kk] = undefined
            endif
        endfor

    else
        # Non-2×2 or uncorrelated: fall back to Cholesky-scale profiling
        for .kk from 1 to .dVal
            .sgOpt = .thetaML# [.kk] * .sigmaML
            .step = max (.sgOpt * 0.1, 0.05)
            .pinnedIdx = .kk

            .innerInit# = zero# (.dVal)
            .innerLower# = zero# (.dVal)
            .innerUpper# = zero# (.dVal)
            .freeIdx = 0
            for .ii from 1 to .dVal
                if .ii <> .kk
                    .freeIdx = .freeIdx + 1
                    .innerInit# [.freeIdx] = .thetaML# [.ii]
                    .innerLower# [.freeIdx] = emlRandomEffectsZ.thetaLower# [.ii]
                    .innerUpper# [.freeIdx] = 1e30
                endif
            endfor
            .innerInit# [.dVal] = .sigmaML
            .innerLower# [.dVal] = 0.001
            .innerUpper# [.dVal] = 1e30

            # Lower bracket
            .sgFloor = -1e30
            if emlRandomEffectsZ.thetaLower# [.kk] >= 0
                .sgFloor = 0.001
            else
                .sgFloor = -10 * max (abs (.sgOpt), .sigmaML)
            endif
            .sgLo = .sgOpt
            .found = 0
            .iter = 0
            .wsPoint# = .innerInit#
            repeat
                .sgLo = .sgLo - .step
                if .sgLo < .sgFloor
                    .sgLo = .sgFloor
                    .found = -1
                endif
                .pinnedSgVal = .sgLo
                @emlNelderMead: "emlProfileObjSig01", .wsPoint#,
                    ... .innerLower#, .innerUpper#, 1e-6, 300
                .wsPoint# = emlNelderMead.xOpt#
                .mlDev = emlNelderMead.fOpt
                .iter = .iter + 1
                if .mlDev - .mlDevOpt >= .cutoff
                    .found = 1
                endif
            until .found <> 0 or .iter > 50

            if .found = 1
                .bsHi = .sgOpt
                .bsLo = .sgLo
                for .bisect from 1 to 15
                    .bsMid = (.bsHi + .bsLo) / 2
                    .pinnedSgVal = .bsMid
                    @emlNelderMead: "emlProfileObjSig01", .wsPoint#,
                        ... .innerLower#, .innerUpper#, 1e-6, 200
                    .wsPoint# = emlNelderMead.xOpt#
                    .mlDev = emlNelderMead.fOpt
                    if .mlDev - .mlDevOpt < .cutoff
                        .bsHi = .bsMid
                    else
                        .bsLo = .bsMid
                    endif
                endfor
                .lowerSig01# [.kk] = (.bsHi + .bsLo) / 2
            else
                if emlRandomEffectsZ.thetaLower# [.kk] >= 0
                    .lowerSig01# [.kk] = 0
                else
                    .lowerSig01# [.kk] = undefined
                endif
            endif

            # Upper bracket
            .sgHi = .sgOpt
            .wsPoint# = .innerInit#
            .found = 0
            .iter = 0
            repeat
                .sgHi = .sgHi + .step
                .pinnedSgVal = .sgHi
                @emlNelderMead: "emlProfileObjSig01", .wsPoint#,
                    ... .innerLower#, .innerUpper#, 1e-6, 300
                .wsPoint# = emlNelderMead.xOpt#
                .mlDev = emlNelderMead.fOpt
                .iter = .iter + 1
                if .mlDev - .mlDevOpt >= .cutoff
                    .found = 1
                endif
            until .found = 1 or .iter > 50

            if .found = 1
                .bsLo = .sgOpt
                .bsHi = .sgHi
                for .bisect from 1 to 15
                    .bsMid = (.bsHi + .bsLo) / 2
                    .pinnedSgVal = .bsMid
                    @emlNelderMead: "emlProfileObjSig01", .wsPoint#,
                        ... .innerLower#, .innerUpper#, 1e-6, 200
                    .wsPoint# = emlNelderMead.xOpt#
                    .mlDev = emlNelderMead.fOpt
                    if .mlDev - .mlDevOpt < .cutoff
                        .bsLo = .bsMid
                    else
                        .bsHi = .bsMid
                    endif
                endfor
                .upperSig01# [.kk] = (.bsHi + .bsLo) / 2
            else
                .upperSig01# [.kk] = undefined
            endif
        endfor
    endif

    emlLMM.useREML = .savedUseREML

    # Step 3 (multi-theta): sigma CI
    .sigStep = max (.sigmaML * 0.05, 0.01)
    .thetaLowerAll# = emlRandomEffectsZ.thetaLower#
    .thetaUpperAll# = zero# (.dVal)
    for .ii from 1 to .dVal
        .thetaUpperAll# [.ii] = 1e30
    endfor

    # --- Sigma lower bound ---
    .sigProbe = .sigmaML
    .foundSigLo = 0
    .wsTheta# = .thetaML#
    .sigIter = 0
    repeat
        .sigProbe = .sigProbe - .sigStep
        if .sigProbe < 0.01
            .sigProbe = 0.01
            .foundSigLo = -1
        endif
        .fixedSigma = .sigProbe
        @emlNelderMead: "emlProfileObjSigma", .wsTheta#,
            ... .thetaLowerAll#, .thetaUpperAll#, 1e-6, 300
        .wsTheta# = emlNelderMead.xOpt#
        .dd2Min = emlNelderMead.fOpt
        .sigIter = .sigIter + 1
        if .dd2Min - .mlDevOpt >= .cutoff
            .foundSigLo = 1
        endif
    until .foundSigLo <> 0 or .sigIter > 60

    if .foundSigLo = 1
        .bsSigHi = .sigmaML
        .bsSigLo = .sigProbe
        for .bsI from 1 to 15
            .bsSigMid = (.bsSigHi + .bsSigLo) / 2
            .fixedSigma = .bsSigMid
            @emlNelderMead: "emlProfileObjSigma", .wsTheta#,
                ... .thetaLowerAll#, .thetaUpperAll#, 1e-6, 200
            .wsTheta# = emlNelderMead.xOpt#
            .dd2Min = emlNelderMead.fOpt
            if .dd2Min - .mlDevOpt < .cutoff
                .bsSigHi = .bsSigMid
            else
                .bsSigLo = .bsSigMid
            endif
        endfor
        .lowerSigma = (.bsSigHi + .bsSigLo) / 2
    else
        .lowerSigma = 0
    endif

    # --- Sigma upper bound ---
    .sigProbe = .sigmaML
    .foundSigHi = 0
    .wsTheta# = .thetaML#
    .sigIter = 0
    repeat
        .sigProbe = .sigProbe + .sigStep
        .fixedSigma = .sigProbe
        @emlNelderMead: "emlProfileObjSigma", .wsTheta#,
            ... .thetaLowerAll#, .thetaUpperAll#, 1e-6, 300
        .wsTheta# = emlNelderMead.xOpt#
        .dd2Min = emlNelderMead.fOpt
        .sigIter = .sigIter + 1
        if .dd2Min - .mlDevOpt >= .cutoff
            .foundSigHi = 1
        endif
    until .foundSigHi = 1 or .sigIter > 60

    if .foundSigHi = 1
        .bsSigLo = .sigmaML
        .bsSigHi = .sigProbe
        for .bsI from 1 to 15
            .bsSigMid = (.bsSigHi + .bsSigLo) / 2
            .fixedSigma = .bsSigMid
            @emlNelderMead: "emlProfileObjSigma", .wsTheta#,
                ... .thetaLowerAll#, .thetaUpperAll#, 1e-6, 200
            .wsTheta# = emlNelderMead.xOpt#
            .dd2Min = emlNelderMead.fOpt
            if .dd2Min - .mlDevOpt < .cutoff
                .bsSigLo = .bsSigMid
            else
                .bsSigHi = .bsSigMid
            endif
        endfor
        .upperSigma = (.bsSigHi + .bsSigLo) / 2
    else
        .upperSigma = undefined
    endif

    label PROFILE_BETA_CI

    # Beta CIs: Wald with Satterthwaite df
    .lowerBeta# = zero# (.pVal)
    .upperBeta# = zero# (.pVal)
    for .jj from 1 to .pVal
        .dfVal = emlLMM.dfBeta# [.jj]
        .tCrit = invStudentQ ((1 - .level) / 2, .dfVal)
        .lowerBeta# [.jj] = emlLMM.beta# [.jj] - .tCrit * emlLMM.seBeta# [.jj]
        .upperBeta# [.jj] = emlLMM.beta# [.jj] + .tCrit * emlLMM.seBeta# [.jj]
    endfor
endproc

# ============================================================================
# @emlBootstrapCI
# Parametric bootstrap confidence intervals.
# Input: .level (e.g. 0.95), .nBoot (number of bootstrap samples)
# Output: .lowerBeta##, .upperBeta## as vectors; .lowerSigma, .upperSigma
# ============================================================================
procedure emlBootstrapCI: .level, .nBoot
    .pVal = emlLMM.nFixedCols
    .nVal = emlLMM.nObs
    .qVal = emlLMM.nRandomCols
    .alpha = 1 - .level

    # Store original fit results
    .betaOrig# = emlLMM.beta#
    .sigmaOrig = emlLMM.sigma
    .thetaOrig# = emlLMM.thetaOpt#
    .xOrig## = emlLMM.x##
    .zOrig## = emlLMM.z##
    .formula$ = emlLMM.formula$
    .contrastCoding$ = emlLMM.contrastCoding$
    .useREML = emlLMM.useREML

    # Compute Lambda for simulating random effects
    @emlConstructLambda: .thetaOrig#
    .lambdaOrig## = emlConstructLambda.lambda##

    # Allocate storage for bootstrap results
    .bootBeta## = zero## (.nBoot, .pVal)
    .bootSigma# = zero# (.nBoot)

    # Create a copy of the original table for bootstrap samples
    selectObject: emlLMM.tableId
    .bootTable = Copy: "bootstrap"
    .responseCol$ = emlLMM.responseVar$

    for .bb from 1 to .nBoot
        # Simulate random effects: b = sigma * Lambda * z, z ~ N(0, I_q)
        .zVec# = zero# (.qVal)
        for .ii from 1 to .qVal
            .zVec# [.ii] = randomGauss (0, 1)
        endfor
        .bVec# = zero# (.qVal)
        for .ii from 1 to .qVal
            for .jj from 1 to .qVal
                .bVec# [.ii] = .bVec# [.ii] + .sigmaOrig * .lambdaOrig## [.ii, .jj] * .zVec# [.jj]
            endfor
        endfor

        # Simulate y* = X*beta + Z*b + epsilon, epsilon ~ N(0, sigma^2)
        .xBeta# = mul# (.xOrig##, .betaOrig#)
        .zB# = mul# (.zOrig##, .bVec#)
        for .ii from 1 to .nVal
            .yStar = .xBeta# [.ii] + .zB# [.ii] + randomGauss (0, .sigmaOrig)
            selectObject: .bootTable
            Set numeric value: .ii, .responseCol$, .yStar
        endfor

        # Refit model
        @emlLMM: .bootTable, .formula$, .contrastCoding$, .useREML, 5000
        if emlLMM.converged
            for .jj from 1 to .pVal
                .bootBeta## [.bb, .jj] = emlLMM.beta# [.jj]
            endfor
            .bootSigma# [.bb] = emlLMM.sigma
        else
            # Mark failed bootstrap sample with undefined
            for .jj from 1 to .pVal
                .bootBeta## [.bb, .jj] = undefined
            endfor
            .bootSigma# [.bb] = undefined
        endif
    endfor

    removeObject: .bootTable

    # Compute percentile CIs
    .loIdx = max (1, floor (.nBoot * .alpha / 2))
    .hiIdx = min (.nBoot, ceiling (.nBoot * (1 - .alpha / 2)))

    .lowerBeta# = zero# (.pVal)
    .upperBeta# = zero# (.pVal)
    for .jj from 1 to .pVal
        # Extract column and sort
        .col# = zero# (.nBoot)
        .nValid = 0
        for .bb from 1 to .nBoot
            if .bootBeta## [.bb, .jj] <> undefined
                .nValid = .nValid + 1
                .col# [.nValid] = .bootBeta## [.bb, .jj]
            endif
        endfor
        if .nValid > 10
            .validCol# = zero# (.nValid)
            for .ii from 1 to .nValid
                .validCol# [.ii] = .col# [.ii]
            endfor
            .sorted# = sort# (.validCol#)
            .loI = max (1, floor (.nValid * .alpha / 2))
            .hiI = min (.nValid, ceiling (.nValid * (1 - .alpha / 2)))
            .lowerBeta# [.jj] = .sorted# [.loI]
            .upperBeta# [.jj] = .sorted# [.hiI]
        else
            .lowerBeta# [.jj] = undefined
            .upperBeta# [.jj] = undefined
        endif
    endfor

    # Sigma CI
    .nValidSig = 0
    .sigCol# = zero# (.nBoot)
    for .bb from 1 to .nBoot
        if .bootSigma# [.bb] <> undefined
            .nValidSig = .nValidSig + 1
            .sigCol# [.nValidSig] = .bootSigma# [.bb]
        endif
    endfor
    if .nValidSig > 10
        .validSig# = zero# (.nValidSig)
        for .ii from 1 to .nValidSig
            .validSig# [.ii] = .sigCol# [.ii]
        endfor
        .sorted# = sort# (.validSig#)
        .loI = max (1, floor (.nValidSig * .alpha / 2))
        .hiI = min (.nValidSig, ceiling (.nValidSig * (1 - .alpha / 2)))
        .lowerSigma = .sorted# [.loI]
        .upperSigma = .sorted# [.hiI]
    else
        .lowerSigma = undefined
        .upperSigma = undefined
    endif

    .nFailed = .nBoot - .nValid
endproc

# ============================================================================
# @emlLikelihoodRatioTest
# Compare two nested models via likelihood ratio test.
# Both models are fit using ML (not REML — LRT requires ML).
# Includes Stram & Lee (1994) boundary correction for testing variance
# components, and Self & Liang (1987) extension for multiple components.
# Input: .tableId, .formulaFull$, .formulaReduced$, .contrastCoding$
# Output: .chi2, .dfTest, .pStandard, .pBoundary, .nVarCompsRemoved
# ============================================================================
procedure emlLikelihoodRatioTest: .tableId, .formulaFull$, .formulaReduced$, .contrastCoding$
    # Fit full model (ML)
    @emlLMM: .tableId, .formulaFull$, .contrastCoding$, 0, 10000
    .devFull = emlLMM.deviance
    .logLikFull = emlLMM.logLik
    .nParsFull = emlLMM.nFixedCols + size (emlLMM.thetaOpt#) + 1
    .thetaSizeFull = size (emlLMM.thetaOpt#)
    .convergedFull = emlLMM.converged

    # Parse reduced formula to check for random effects
    @emlParseFormula: .formulaReduced$
    .reducedHasRE = emlParseFormula.nRandom

    if .reducedHasRE > 0
        # Fit reduced model as LMM (ML)
        @emlLMM: .tableId, .formulaReduced$, .contrastCoding$, 0, 10000
        .devReduced = emlLMM.deviance
        .logLikReduced = emlLMM.logLik
        .nParsReduced = emlLMM.nFixedCols + size (emlLMM.thetaOpt#) + 1
        .thetaSizeReduced = size (emlLMM.thetaOpt#)
    else
        # Reduced model is pure OLS — compute ML fit manually
        @emlModelMatrix: .tableId, .contrastCoding$
        .xR## = emlModelMatrix.x##
        .nR = emlModelMatrix.n
        .pR = emlModelMatrix.p
        selectObject: .tableId
        .yR# = zero# (.nR)
        for .row from 1 to .nR
            selectObject: .tableId
            .rv$ = Get value: .row, emlParseFormula.response$
            .yR# [.row] = number (.rv$)
        endfor
        # OLS: beta = (X'X)^{-1} X'y
        .xtx## = mul## (transpose## (.xR##), .xR##)
        .xty# = mul# (transpose## (.xR##), .yR#)
        @emlCholeskySolve: .xtx##, .xty#
        .betaOLS# = emlCholeskySolve.x#
        .residOLS# = .yR# - mul# (.xR##, .betaOLS#)
        .rss = inner (.residOLS#, .residOLS#)
        .sigSqOLS = .rss / .nR
        .devReduced = .nR * (1 + ln (2 * pi * .sigSqOLS))
        .logLikReduced = -0.5 * .devReduced
        .nParsReduced = .pR + 1
        .thetaSizeReduced = 0
    endif

    # LRT statistic
    .chi2 = .devReduced - .devFull
    if .chi2 < 0
        .chi2 = 0
    endif
    .dfTest = .nParsFull - .nParsReduced

    # Standard chi-square p-value
    if .dfTest > 0
        .pStandard = chiSquareQ (.chi2, .dfTest)
    else
        .pStandard = 1
    endif

    # Determine if variance components were removed
    .nVarCompsRemoved = .thetaSizeFull - .thetaSizeReduced
    .nFixedRemoved = .dfTest - .nVarCompsRemoved

    # Boundary correction
    if .nVarCompsRemoved > 0 and .nFixedRemoved = 0
        # Testing only variance components — boundary correction needed
        # Self & Liang (1987): mixture of chi-squares
        .qComp = .nVarCompsRemoved
        .pBoundary = 0
        .twoToQ = 2 ^ .qComp
        for .kk from 0 to .qComp
            .binom = 1
            for .mm from 1 to .kk
                .binom = .binom * (.qComp - .mm + 1) / .mm
            endfor
            .weight = .binom / .twoToQ
            if .kk = 0
                if .chi2 < 0
                    .pBoundary = .pBoundary + .weight
                endif
            else
                .pBoundary = .pBoundary + .weight * chiSquareQ (.chi2, .kk)
            endif
        endfor
    elsif .nVarCompsRemoved > 0 and .nFixedRemoved > 0
        .pBoundary = .pStandard
    else
        .pBoundary = .pStandard
    endif
endproc

# ============================================================================
# @emlJohnsonR2
# Marginal and conditional R-squared following Johnson (2014).
# Extends Nakagawa & Schielzeth (2013) for random slopes.
# Must be called after @emlLMM.
# Output: .r2Marginal, .r2Conditional, .varFixed, .varRandom, .varResidual
# ============================================================================
procedure emlJohnsonR2
    .nVal = emlLMM.nObs
    .pVal = emlLMM.nFixedCols
    .sigSq = emlLMM.sigma * emlLMM.sigma

    # Variance of fixed-effects predictions: var(X * beta)
    .xBeta# = mul# (emlLMM.x##, emlLMM.beta#)
    .meanXBeta = 0
    for .ii from 1 to .nVal
        .meanXBeta = .meanXBeta + .xBeta# [.ii]
    endfor
    .meanXBeta = .meanXBeta / .nVal
    .varFixed = 0
    for .ii from 1 to .nVal
        .dev = .xBeta# [.ii] - .meanXBeta
        .varFixed = .varFixed + .dev * .dev
    endfor
    .varFixed = .varFixed / (.nVal - 1)

    # Variance of random effects: canonical Nakagawa & Schielzeth (2013) /
    # Johnson (2014) — the mean over observations of the model-implied RE
    # variance, varRandom = mean(diag(Z*Sigma*Z')), where Sigma is the
    # block-diagonal RE covariance (each grouping level shares that term's
    # covariance block). This equals sum(VarCorr) ONLY for random intercepts;
    # for random slopes it is tau0^2 + 2*tau01*mean(x) + tau1^2*mean(x^2),
    # which matches performance::r2_nakagawa / MuMIn::r.squaredGLMM.
    # Supersedes the earlier sum(VarCorr) form (v0.8 "Fix 2"), which was wrong
    # by up to ~0.11 for random-slope models.
    .qVal = emlLMM.nRandomCols
    .sigmaFull## = zero## (.qVal, .qVal)
    for .jj from 1 to emlRandomEffectsZ.nTerms
        .mEff = emlRandomEffectsZ.termNEffects'.jj'
        .nLev = emlRandomEffectsZ.termNLevels'.jj'
        .blkStart = emlRandomEffectsZ.termStart'.jj'
        for .lev from 1 to .nLev
            .base = .blkStart + (.lev - 1) * .mEff - 1
            for .rr from 1 to .mEff
                for .cc from 1 to .mEff
                    .sigmaFull## [.base + .rr, .base + .cc] = emlLMM.varCov'.jj'## [.rr, .cc]
                endfor
            endfor
        endfor
    endfor
    .zSigma## = mul## (emlLMM.z##, .sigmaFull##)
    .varRandom = 0
    for .ii from 1 to .nVal
        .quad = 0
        for .kk from 1 to .qVal
            .quad = .quad + .zSigma## [.ii, .kk] * emlLMM.z## [.ii, .kk]
        endfor
        .varRandom = .varRandom + .quad
    endfor
    .varRandom = .varRandom / .nVal

    .varResidual = .sigSq

    # R-squared
    .totalVar = .varFixed + .varRandom + .varResidual
    .r2Marginal = .varFixed / .totalVar
    .r2Conditional = (.varFixed + .varRandom) / .totalVar
endproc

# ============================================================================
# @emlLMMResiduals
# Compute raw, Pearson, and scaled residuals.
# Must be called after @emlLMM.
# Output: .raw#, .pearson#, .scaled#
# ============================================================================
procedure emlLMMResiduals
    .nVal = emlLMM.nObs
    .raw# = emlLMM.residuals#

    # Pearson residuals for a Gaussian, unit-weight LMM equal the raw residuals
    # (Pearson = raw / sqrt(weight), weight = 1). This matches lme4's
    # residuals(type = "pearson"); the two fields are intentionally identical.
    .pearson# = emlLMM.residuals#

    # Scaled residuals: raw / sigma (lme4 residuals(., scaled = TRUE)).
    .scaled# = emlLMM.residuals# * (1 / emlLMM.sigma)
endproc

# ============================================================================
# @emlLMMInfluence
# Hat values, Cook's distance, and DFBETAS.
# Uses one-step approximation (no model refitting).
# Must be called after @emlLMM.
# Output: .hatValues#, .cooksD#, .dfbetas## (n × p)
# ============================================================================
procedure emlLMMInfluence
    .nVal = emlLMM.nObs
    .pVal = emlLMM.nFixedCols
    .sigSq = emlLMM.sigma * emlLMM.sigma

    # Hat matrix: H = X (X'V^{-1}X)^{-1} X' V^{-1}
    # For the profiled model: H ≈ X * vcov/sigma^2 * X' * (1/sigma^2)
    # Simplified: h_i = x_i' * (X'V^{-1}X)^{-1} * x_i / sigma^2... but V is complex
    # Use the standard LMM hat matrix formula via the augmented system

    # Approximate hat values from the augmented projection
    # H_full = [X Z*Lambda] * [[X'X, X'ZL], [ZL'X, ZL'ZL+I]]^{-1} * [X ZL]'
    @emlConstructLambda: emlLMM.thetaOpt#
    .lambda## = emlConstructLambda.lambda##
    .zl## = mul## (emlLMM.z##, .lambda##)
    .qVal = emlLMM.nRandomCols

    # Augmented matrix: C = [[X'X, X'ZL], [ZL'X, ZL'ZL+I]]
    .dimC = .pVal + .qVal
    .c## = zero## (.dimC, .dimC)
    .xtx## = mul## (transpose## (emlLMM.x##), emlLMM.x##)
    .xtzl## = mul## (transpose## (emlLMM.x##), .zl##)
    .zltx## = transpose## (.xtzl##)
    .zltzl## = mul## (transpose## (.zl##), .zl##)
    for .ii from 1 to .qVal
        .zltzl## [.ii, .ii] = .zltzl## [.ii, .ii] + 1
    endfor

    # Fill C using part## block writes (p and q are small)
    for .ii from 1 to .pVal
        for .jj from 1 to .pVal
            .c## [.ii, .jj] = .xtx## [.ii, .jj]
        endfor
        for .jj from 1 to .qVal
            .c## [.ii, .pVal + .jj] = .xtzl## [.ii, .jj]
            .c## [.pVal + .jj, .ii] = .zltx## [.jj, .ii]
        endfor
    endfor
    for .ii from 1 to .qVal
        for .jj from 1 to .qVal
            .c## [.pVal + .ii, .pVal + .jj] = .zltzl## [.ii, .jj]
        endfor
    endfor

    # C^{-1} via native solve##
    .cEye## = zero## (.dimC, .dimC)
    for .ii from 1 to .dimC
        .cEye## [.ii, .ii] = 1
    endfor
    .cInv## = solve## (.c##, .cEye##)

    # Hat values via rowInners# — replaces N × (p+q) per-obs loop
    # Build augmented design [X, ZL] (n × dimC)
    .aug## = zero## (.nVal, .dimC)
    for .jj from 1 to .pVal
        .col# = rowSums# (part## (emlLMM.x##, 1, .nVal, .jj, .jj))
        for .ii from 1 to .nVal
            .aug## [.ii, .jj] = .col# [.ii]
        endfor
    endfor
    for .jj from 1 to .qVal
        .col# = rowSums# (part## (.zl##, 1, .nVal, .jj, .jj))
        for .ii from 1 to .nVal
            .aug## [.ii, .pVal + .jj] = .col# [.ii]
        endfor
    endfor
    # h_i = [x_i; zl_i]' C^{-1} [x_i; zl_i] = rowInners#(aug * C^{-1}, aug)
    .augCinv## = mul## (.aug##, .cInv##)
    .hatValues# = rowInners# (.augCinv##, .aug##)

    # Influence on the FIXED effects uses the MARGINAL residual r_i = y_i -
    # x_i'beta (population-level), not the conditional residual y_i - x_i'beta -
    # z_i'b. Cook's D and DFBETA measure how obs i moves beta; the conditional
    # residual removes the random-effect part and understates that leverage.
    # (M5 fix.) These remain ONE-STEP (no-refit) approximations: they preserve
    # the influence RANKING of observations but are not equal in magnitude to
    # case-deletion refitting (influence.ME) — a single deletion in a grouped
    # design is partly absorbed by the random effects, so case-deletion values
    # are systematically smaller. Use for screening relative influence.
    .marginalFit# = mul# (emlLMM.x##, emlLMM.beta#)
    .r# = emlLMM.y# - .marginalFit#

    # Cook's distance — vectorized
    # D_i = r_i^2 * h_i / (p * sigma^2 * (1-h_i)^2)
    .cooksD# = zero# (.nVal)
    .oneMinusH# = zero# (.nVal)
    for .ii from 1 to .nVal
        .oneMinusH# [.ii] = 1 - .hatValues# [.ii]
    endfor
    for .ii from 1 to .nVal
        if .hatValues# [.ii] < 1
            .cooksD# [.ii] = (.r# [.ii] * .r# [.ii] * .hatValues# [.ii]) /
                ... (.pVal * .sigSq * .oneMinusH# [.ii] * .oneMinusH# [.ii])
        else
            .cooksD# [.ii] = undefined
        endif
    endfor

    # DFBETAS — vectorized via matrix multiply
    # dfbeta[i,j] = sum_k(vcov[j,k] * X[i,k]) * r_i / ((1-h_i) * sigma^2)
    # = (X * vcov')[i,j] * scale[i]  where scale_i = r_i / ((1-h_i)*sigma^2)
    # vcov is symmetric so vcov' = vcov
    .rawDfbeta## = mul## (emlLMM.x##, emlLMM.vcovBeta##)
    .dfbetas## = zero## (.nVal, .pVal)
    for .ii from 1 to .nVal
        if .hatValues# [.ii] < 1
            .scale = .r# [.ii] / (.oneMinusH# [.ii] * .sigSq)
            for .jj from 1 to .pVal
                .dfbetas## [.ii, .jj] = .rawDfbeta## [.ii, .jj] * .scale /
                    ... emlLMM.seBeta# [.jj]
            endfor
        endif
    endfor
endproc

# @emlOLSInfluence moved to stats/eml-inferential.praat beside
# @emlLinearRegression. It has no LMM dependency, and eml-lib.praat (which
# eml-regress.praat includes) does not pull in this file, so it was
# unreachable from the regression path while it lived here.


# ============================================================================
# @emlLMMPredict
# Predictions from a fitted LMM for new data.
# Input: .newTableId (Table with same predictor columns)
#        .includeRE (1 = include random effects, 0 = fixed only)
# Output: .predicted#, .sePred# (prediction SE)
# ============================================================================
procedure emlLMMPredict: .newTableId, .includeRE
    .pVal = emlLMM.nFixedCols

    # Build X_new from the new table using the same formula
    selectObject: .newTableId
    .nNew = Get number of rows

    # Build design matrix for new data
    # Need to use the same contrast coding and formula
    @emlModelMatrix: .newTableId, emlLMM.contrastCoding$
    .xNew## = emlModelMatrix.x##

    # Fixed-effects predictions
    .predicted# = mul# (.xNew##, emlLMM.beta#)

    # SE of fixed-effects predictions: SE = sqrt(x_i' * vcov * x_i)
    .sePred# = zero# (.nNew)
    for .ii from 1 to .nNew
        .xRow# = zero# (.pVal)
        for .jj from 1 to .pVal
            .xRow# [.jj] = .xNew## [.ii, .jj]
        endfor
        .varPred = inner (.xRow#, mul# (emlLMM.vcovBeta##, .xRow#))
        .sePred# [.ii] = sqrt (.varPred)
    endfor

    # Add random effects if requested
    if .includeRE
        # Build Z_new and compute Z_new * b
        @emlRandomEffectsZ: .newTableId, emlLMM.contrastCoding$
        .zNew## = emlRandomEffectsZ.z##

        # b = sigma * Lambda * u
        @emlConstructLambda: emlLMM.thetaOpt#
        .lambdaU# = mul# (emlConstructLambda.lambda##, emlLMM.u#)
        .bVec# = zero# (emlLMM.nRandomCols)
        for .ii from 1 to emlLMM.nRandomCols
            .bVec# [.ii] = emlLMM.sigma * .lambdaU# [.ii]
        endfor
        .reContrib# = mul# (.zNew##, .bVec#)
        for .ii from 1 to .nNew
            .predicted# [.ii] = .predicted# [.ii] + .reContrib# [.ii]
        endfor

        # SE with RE includes conditional variance (approximate)
        # var(y_new) ≈ x' vcov x + z' G z + sigma^2
        for .ii from 1 to .nNew
            .zRow# = zero# (emlLMM.nRandomCols)
            for .jj from 1 to emlLMM.nRandomCols
                .zRow# [.jj] = .zNew## [.ii, .jj]
            endfor
            # Add random effect variance contribution
            .lU# = mul# (emlConstructLambda.lambda##, .zRow#)
            .reVar = emlLMM.sigma * emlLMM.sigma * inner (.lU#, .lU#)
            .sePred# [.ii] = sqrt (.sePred# [.ii] * .sePred# [.ii] + .reVar)
        endfor
    endif
endproc

# ============================================================================
# @emlLMMSummary
# Print a formatted summary matching lmerTest::summary() style.
# Must be called after @emlLMM.
# Output: writes to Info window
# ============================================================================
procedure emlLMMSummary
    .nVal = emlLMM.nObs
    .pVal = emlLMM.nFixedCols

    writeInfoLine: "Linear mixed model fit by ",
        ... if emlLMM.useREML then "REML" else "ML" fi
    appendInfoLine: "Formula: ", emlLMM.formula$
    appendInfoLine: ""

    # REML criterion
    if emlLMM.useREML
        appendInfoLine: "REML criterion at convergence: ", fixed$ (emlLMM.deviance, 1)
    else
        appendInfoLine: "     AIC      BIC   logLik deviance"
        appendInfoLine: fixed$ (emlLMM.aic, 1), "  ",
            ... fixed$ (emlLMM.bic, 1), "  ",
            ... fixed$ (emlLMM.logLik, 1), "  ",
            ... fixed$ (emlLMM.deviance, 1)
    endif
    appendInfoLine: ""

    # Scaled residuals
    @emlLMMResiduals
    .sortedScaled# = sort# (emlLMMResiduals.scaled#)
    .n25 = max (1, floor (.nVal * 0.25))
    .n50 = max (1, floor (.nVal * 0.50))
    .n75 = max (1, floor (.nVal * 0.75))
    appendInfoLine: "Scaled residuals:"
    appendInfoLine: "     Min       1Q   Median       3Q      Max"
    appendInfoLine: fixed$ (.sortedScaled# [1], 4), "  ",
        ... fixed$ (.sortedScaled# [.n25], 4), "  ",
        ... fixed$ (.sortedScaled# [.n50], 4), "  ",
        ... fixed$ (.sortedScaled# [.n75], 4), "  ",
        ... fixed$ (.sortedScaled# [.nVal], 4)
    appendInfoLine: ""

    # Random effects
    appendInfoLine: "Random effects:"
    appendInfoLine: " Groups   Name        Variance Std.Dev.",
        ... if emlRandomEffectsZ.nTerms > 0 and
        ... emlRandomEffectsZ.termNEffects1 > 1 then " Corr" else "" fi
    for .jj from 1 to emlRandomEffectsZ.nTerms
        .groupVar$ = emlParseFormula.reGroup'.jj'$
        .mEff = emlRandomEffectsZ.termNEffects'.jj'
        for .kk from 1 to .mEff
            .var = emlLMM.varCov'.jj'## [.kk, .kk]
            .sd = sqrt (.var)
            .effName$ = emlParseFormula.reTerm'.jj'_'.kk'$
            if .effName$ = "1"
                .effName$ = "(Intercept)"
            endif
            if .kk = 1
                appendInfo: " ", .groupVar$
                # Pad to 9 chars
                .padLen = 9 - length (.groupVar$)
                for .pp from 1 to .padLen
                    appendInfo: " "
                endfor
            else
                appendInfo: "          "
            endif
            appendInfo: .effName$
            .padLen2 = 12 - length (.effName$)
            for .pp from 1 to .padLen2
                appendInfo: " "
            endfor
            appendInfo: fixed$ (.var, 4), " ", fixed$ (.sd, 4)
            # Correlations
            if .kk > 1
                .corr = emlLMM.varCov'.jj'## [.kk, 1] /
                    ... (sqrt (emlLMM.varCov'.jj'## [.kk, .kk]) *
                    ... sqrt (emlLMM.varCov'.jj'## [1, 1]))
                appendInfo: "  ", fixed$ (.corr, 2)
            endif
            appendInfoLine: ""
        endfor
    endfor
    appendInfoLine: " Residual              ", fixed$ (emlLMM.sigma * emlLMM.sigma, 4),
        ... " ", fixed$ (emlLMM.sigma, 4)
    appendInfoLine: "Number of obs: ", .nVal

    # Group counts
    for .jj from 1 to emlRandomEffectsZ.nTerms
        .groupVar$ = emlParseFormula.reGroup'.jj'$
        .nLev = emlRandomEffectsZ.termNLevels'.jj'
        appendInfoLine: ", ", .groupVar$, ": ", .nLev
    endfor
    appendInfoLine: ""

    # Fixed effects
    appendInfoLine: "Fixed effects:"
    appendInfoLine: "              Estimate Std. Error       df t value Pr(>|t|)"
    for .jj from 1 to .pVal
        if .jj = 1
            .name$ = "(Intercept)"
        else
            .termIdx = .jj - emlParseFormula.hasIntercept
            if .termIdx >= 1 and .termIdx <= emlParseFormula.nFixed
                .name$ = emlParseFormula.fixedTerm'.termIdx'$
            else
                .name$ = "coef" + string$ (.jj)
            endif
        endif
        # Pad name to 14 chars
        appendInfo: .name$
        .padLen = 15 - length (.name$)
        for .pp from 1 to .padLen
            appendInfo: " "
        endfor
        appendInfo: fixed$ (emlLMM.beta# [.jj], 6), " "
        appendInfo: fixed$ (emlLMM.seBeta# [.jj], 6), " "
        appendInfo: fixed$ (emlLMM.dfBeta# [.jj], 2), " "
        appendInfo: fixed$ (emlLMM.tBeta# [.jj], 3), " "
        # Format p-value
        if emlLMM.pBeta# [.jj] < 2e-16
            appendInfo: "< 2e-16"
        else
            appendInfo: string$ (emlLMM.pBeta# [.jj])
        endif
        # Significance stars
        if emlLMM.pBeta# [.jj] < 0.001
            appendInfo: " ***"
        elsif emlLMM.pBeta# [.jj] < 0.01
            appendInfo: " **"
        elsif emlLMM.pBeta# [.jj] < 0.05
            appendInfo: " *"
        elsif emlLMM.pBeta# [.jj] < 0.1
            appendInfo: " ."
        endif
        appendInfoLine: ""
    endfor
    appendInfoLine: "---"
    appendInfoLine: "Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1"

    if emlLMM.isSingular
        appendInfoLine: ""
        appendInfoLine: "convergence code: 0"
        appendInfoLine: "boundary (singular) fit: see help('isSingular')"
    endif
endproc


# ============================================================================
# @emlRunLMMAnalysis — Linear mixed model orchestrator (Phase 4).
# Shared entry point for the menu front-end, the wizard, and the direct API.
#
# Moved here from stats/eml-analysis.praat on 6 August 2026 so that the
# orchestrator and the engine it calls cannot be included separately. See
# the note left at its old location.
# Wraps the verified EML LMM engine (@emlLMM) and its lme4-style reporter
# (@emlLMMSummary), then appends marginal/conditional R-squared and, on
# request, 95% Wald CIs. DRY: every path calls THIS, so a change here
# propagates to all of them.
#
# Input:  .tableId          — Table with the response + predictor + group cols
#         .formula$         — lme4-style formula, e.g. "y ~ x + (1 + x | group)"
#         .contrastCoding$  — "treatment" / "sum" / "helmert" / "poly"
#         .useREML          — 1 = REML (default), 0 = ML
#         .doR2             — 1 = append Nakagawa/Johnson R-squared
#         .doCI             — 1 = append 95% Wald CIs for fixed effects
# Output: .error$           — non-empty on failure (nothing printed)
# ============================================================================
procedure emlRunLMMAnalysis: .tableId, .formula$, .contrastCoding$, .useREML, .doR2, .doCI
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    ;
    ; THIS ORCHESTRATOR DOES NOT DECLARE, AND THAT IS WHY IT NEEDS THIS MOST.
    ; It is the one emlRun...Analysis orchestrator that declares nothing --
    ; it calls no emlDeclare... procedure of any kind -- so without this line
    ; it never touches emlResult_declared or the broom collectors at all, and
    ; simply INHERITS whatever the previous analysis left in them. (Those two
    ; name prefixes are written bare, without the usual call sigil, on
    ; purpose: harness/check_includes.py strips # comments but not ; ones,
    ; and would read a wildcard name here as a call to a procedure that does
    ; not exist.)
    ; Measured 14 Aug 2026 on the API path: ANOVA, then LMM, then
    ; @emlExportResultFiles wrote five frames whose glance said
    ; method = One-way ANOVA under the LMM's own base name. The clear turns
    ; that into an honest empty export (declared = 0, reason = "empty").
    ;
    ; THIS IS ON THE API PATH, NOT A MENU ONE. Mixed models are TABLED for
    ; end users -- setup.praat registers no menu entry and no Objects-window
    ; button, and the wizard has no route into them (eml-wizard,
    ; "elsif goal = 4") -- so no dialog can reach this procedure. A user's own
    ; Praat script can -- @emlRunLMMAnalysis and @emlExportResultFiles are
    ; both callable directly -- and that is the path this closes.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlLMM: .tableId, .formula$, .contrastCoding$, .useREML, 3000
    if emlLMM.error$ <> ""
        .error$ = emlLMM.error$
        goto END_LMM_ORCH
    endif

    # Standard lme4-style summary (engine's own reporter — reused, not copied).
    @emlLMMSummary

    # Marginal / conditional R-squared (canonical Nakagawa/Johnson).
    if .doR2
        @emlJohnsonR2
        appendInfoLine: ""
        .r2mLine$ = "Marginal R" + "^2" + " (fixed effects): "
            ... + fixed$ (emlJohnsonR2.r2Marginal, 4)
        appendInfoLine: .r2mLine$
        .r2cLine$ = "Conditional R" + "^2" + " (fixed + random): "
            ... + fixed$ (emlJohnsonR2.r2Conditional, 4)
        appendInfoLine: .r2cLine$
    endif

    # 95% Wald confidence intervals for the fixed effects (t / Satterthwaite df).
    if .doCI
        @emlWaldCI: 0.95
        appendInfoLine: ""
        .ciHdr$ = "95% Wald confidence intervals (fixed effects):"
        appendInfoLine: .ciHdr$
        for .j from 1 to emlLMM.nFixedCols
            .cn$ = emlModelMatrix.colName'.j'$
            .lo$ = fixed$ (emlWaldCI.lower# [.j], 4)
            .hi$ = fixed$ (emlWaldCI.upper# [.j], 4)
            .ciRow$ = "  " + .cn$ + ": [" + .lo$ + ", " + .hi$ + "]"
            appendInfoLine: .ciRow$
        endfor
    endif

    if emlLMM.converged = 0
        appendInfoLine: ""
        .warnLine$ = "WARNING: the optimizer did not fully converge — "
            ... + "interpret estimates with caution (try simplifying the "
            ... + "random-effects structure)."
        appendInfoLine: .warnLine$
    endif

    label END_LMM_ORCH
    selectObject: .tableId
endproc
