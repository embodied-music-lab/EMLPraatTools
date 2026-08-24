# ============================================================================
# EML Stats : Data Extraction Layer
# ============================================================================
# Module: eml-extract.praat
# Version: 1.7
# Date: 24 August 2026
#
#
# Part of the EML Stats library (EML Stats & Graphs).
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
#
# Provides: @emlExtractColumn, @emlExtractColumnAsStrings,
#   @emlExtractGroupVectors, @eml_getGroupData,
#   @emlExtractPairedColumns, @emlExtractPitchValues,
#   @emlExtractFormantValues, @emlExtractIntensityFrames,
#   @emlExtractHarmonicityFrames, @emlValidateTable,
#   @emlValidateNumericColumn, @emlTableColumnNames,
#   @emlCountGroups, @emlGuessColumnRoles,
#   @eml_normalizeLabel, @eml_strictNumericColumn,
#   @emlGroupFingerprint, @emlAnalysisFingerprint, @emlFingerprintsAgree
#
# The fingerprint pair at the foot of this file is the result store's data
# key (docs/RULING_RESULT_STORE.md, §a). It lives HERE, in the extraction
# layer, and not beside either side of the store, because both sides need it:
# the statistics kernels stamp it onto a published result, and the graphs
# layer's annotation bridge recomputes it at draw time to decide whether that
# result still describes the table in front of it. This module is included
# before both.
#
# These procedures extract data from Praat objects into numeric
# vectors suitable for passing to EML Stats statistical procedures.
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
# @emlExtractColumn
# Extract a numeric column from a Table into a vector.
#
# Arguments:
#   tableId     - ID of the Table object
#   columnName$ - name of the column to extract
#
# Output:
#   .data#      - vector of values (length = number of rows)
#   .n          - number of values extracted
#   .nUndefined - count of undefined/non-numeric values
#   .error$     - error message if column doesn't exist, else ""
# ============================================================================
procedure emlExtractColumn: .tableId, .columnName$
    # Initialize outputs
    .n = 0
    .nUndefined = 0
    .nEmpty = 0
    .nLocale = 0
    .nUnreadable = 0
    .nCoerced = 0
    .nLeadingDot = 0
    .note$ = ""
    .error$ = ""
    .data# = zero#(0)

    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns

    # Check if column exists
    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .columnName$
            .colExists = 1
        endif
    endfor

    if .colExists = 0
        .error$ = "Column not found: "
        .error$ = .error$ + .columnName$
    elsif .nRows = 0
        # Empty table - valid but no data
        .data# = zero#(0)
        .n = 0
    else
        # The old body kept every cell for which "Get value:" returned
        # something other than undefined, which sounds like the right filter
        # and is not. Praat coerces "1,5" to 1, so a European decimal comma
        # did not drop a row — it put a DIFFERENT NUMBER into the mean, with
        # nothing anywhere in the report to say so. Rows are now kept only if
        # the cell is strictly the number it looks like, and the reasons the
        # others were dropped are counted separately by @emlAuditColumn.
        #
        # The fast path exists because the classifier probes Praat's
        # numericiser per cell, which is not free. A column that passes the
        # column-level strict test and contains no empty cell cannot contain
        # any of the four bad kinds, so the per-cell pass is skipped.
        @eml_strictNumericColumn: .tableId, .columnName$
        .fastPath = 0
        if eml_strictNumericColumn.strict = 1
            if eml_strictNumericColumn.unreadable = 0
                .fastPath = 1
            endif
        endif

        .data# = zero#(.nRows)
        .n = 0

        if .fastPath = 0
            @emlAuditColumn: .tableId, .columnName$
            .nEmpty = emlAuditColumn.nEmpty
            .nLocale = emlAuditColumn.nLocale
            .nUnreadable = emlAuditColumn.nUnreadable
            .nCoerced = emlAuditColumn.nCoerced
            .nLeadingDot = emlAuditColumn.nLeadingDot
            .note$ = emlAuditColumn.note$
        endif

        for .row from 1 to .nRows
            @eml_readCell: .tableId, .row, .columnName$, .fastPath
            if eml_readCell.value <> undefined
                .n = .n + 1
                .data#[.n] = eml_readCell.value
            endif
        endfor

        .nUndefined = .nRows - .n

        # Resize to actual count if there were undefined values
        if .n < .nRows and .n > 0
            .temp# = zero#(.n)
            for .i from 1 to .n
                .temp#[.i] = .data#[.i]
            endfor
            .data# = .temp#
        elsif .n = 0
            .data# = zero#(0)
        endif
    endif
endproc


# ============================================================================
# @emlExtractColumnAsStrings
# Extract a string column from a Table.
#
# Arguments:
#   tableId     - ID of the Table object
#   columnName$ - name of the column to extract
#
# Output:
#   .n          - number of strings
#   .str$[1..n] - the string values (bracket notation)
#   .error$     - error message if column doesn't exist
# ============================================================================
procedure emlExtractColumnAsStrings: .tableId, .columnName$
    # Initialize outputs
    .n = 0
    .error$ = ""
    
    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns

    # Pre-initialize the string array to the ACTUAL row count, not a fixed cap
    # of 1000. A fixed cap left stale indexed values beyond the cap on tables
    # with >1000 rows; sizing to .nRows removes the cap entirely. (M7)
    for .init from 1 to .nRows
        .str$[.init] = ""
    endfor

    # Check if column exists
    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .columnName$
            .colExists = 1
        endif
    endfor
    
    if .colExists = 0
        .error$ = "Column not found: "
        .error$ = .error$ + .columnName$
    elsif .nRows = 0
        .n = 0
    else
        # Extract string values
        for .row from 1 to .nRows
            selectObject: .tableId
            .val$ = Get value: .row, .columnName$
            .n = .n + 1
            .str$[.n] = .val$
        endfor
    endif
endproc


# ============================================================================
# @emlExtractGroupVectors
# Extract two vectors split by a grouping variable with exactly two levels.
#
# Arguments:
#   tableId     - ID of the Table object
#   measureCol$ - column containing numeric values
#   groupCol$   - column containing group labels
#   label1$     - first group label
#   label2$     - second group label
#
# Output:
#   .group1#    - data vector for label1$
#   .group2#    - data vector for label2$
#   .n1         - size of group 1
#   .n2         - size of group 2
#   .nExcluded  - rows matching neither label
#   .error$     - error message if any
# ============================================================================
procedure emlExtractGroupVectors: .tableId, .measureCol$, .groupCol$, .label1$, .label2$
    # Initialize outputs
    .n1 = 0
    .n2 = 0
    .nExcluded = 0
    .error$ = ""
    .group1# = zero#(0)
    .group2# = zero#(0)
    
    # Select table and get row count
    selectObject: .tableId
    .nRows = Get number of rows
    
    if .nRows = 0
        .error$ = "Table is empty"
    else
        # First pass: count members of each group
        .count1 = 0
        .count2 = 0
        .countExcluded = 0
        
        # One decision per column, then one read path per cell.
        @eml_openColumn: .tableId, .measureCol$
        .measureClean = eml_openColumn.clean

        for .row from 1 to .nRows
            selectObject: .tableId
            .grp$ = Get value: .row, .groupCol$
            @eml_readCell: .tableId, .row, .measureCol$, .measureClean
            .val = eml_readCell.value

            if .val <> undefined
                if .grp$ = .label1$
                    .count1 = .count1 + 1
                elsif .grp$ = .label2$
                    .count2 = .count2 + 1
                else
                    .countExcluded = .countExcluded + 1
                endif
            else
                .countExcluded = .countExcluded + 1
            endif
        endfor
        
        # Allocate vectors
        if .count1 > 0
            .group1# = zero#(.count1)
        endif
        if .count2 > 0
            .group2# = zero#(.count2)
        endif
        
        # Second pass: populate vectors
        .idx1 = 0
        .idx2 = 0
        
        for .row from 1 to .nRows
            selectObject: .tableId
            .grp$ = Get value: .row, .groupCol$
            @eml_readCell: .tableId, .row, .measureCol$, .measureClean
            .val = eml_readCell.value

            if .val <> undefined
                if .grp$ = .label1$
                    .idx1 = .idx1 + 1
                    .group1#[.idx1] = .val
                elsif .grp$ = .label2$
                    .idx2 = .idx2 + 1
                    .group2#[.idx2] = .val
                endif
            endif
        endfor
        
        .n1 = .count1
        .n2 = .count2
        .nExcluded = .countExcluded
    endif
endproc



# ============================================================================
# @emlExtractPairedColumns
# Extract two columns for paired analysis, excluding rows where either is undefined.
#
# Arguments:
#   tableId - ID of the Table object
#   col1$   - name of first column
#   col2$   - name of second column
#
# Output:
#   .data1#       - first column values (complete pairs only)
#   .data2#       - second column values (complete pairs only)
#   .n            - number of complete pairs
#   .nExcludedRows - rows with missing values
#   .error$       - error message if columns don't exist
# ============================================================================
procedure emlExtractPairedColumns: .tableId, .col1$, .col2$
    # Initialize outputs
    .n = 0
    .nExcludedRows = 0
    .error$ = ""
    .data1# = zero#(0)
    .data2# = zero#(0)
    
    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns
    
    # Check if both columns exist
    .col1Exists = 0
    .col2Exists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .col1$
            .col1Exists = 1
        endif
        if .checkName$ = .col2$
            .col2Exists = 1
        endif
    endfor
    
    if .col1Exists = 0
        .error$ = "Column not found: "
        .error$ = .error$ + .col1$
    elsif .col2Exists = 0
        .error$ = "Column not found: "
        .error$ = .error$ + .col2$
    elsif .nRows = 0
        .n = 0
    else
        # First pass: count complete pairs
        .countComplete = 0
        .countExcluded = 0

        # This is the ROW-wise path. It must agree cell for cell with
        # the column-wise paths above, so it reads through the same helper.
        @eml_openColumn: .tableId, .col1$
        .clean1 = eml_openColumn.clean
        @eml_openColumn: .tableId, .col2$
        .clean2 = eml_openColumn.clean

        for .row from 1 to .nRows
            @eml_readCell: .tableId, .row, .col1$, .clean1
            .val1 = eml_readCell.value
            @eml_readCell: .tableId, .row, .col2$, .clean2
            .val2 = eml_readCell.value

            if .val1 <> undefined and .val2 <> undefined
                .countComplete = .countComplete + 1
            else
                .countExcluded = .countExcluded + 1
            endif
        endfor
        
        # Allocate vectors
        if .countComplete > 0
            .data1# = zero#(.countComplete)
            .data2# = zero#(.countComplete)
            
            # Second pass: populate
            .idx = 0
            for .row from 1 to .nRows
                @eml_readCell: .tableId, .row, .col1$, .clean1
                .val1 = eml_readCell.value
                @eml_readCell: .tableId, .row, .col2$, .clean2
                .val2 = eml_readCell.value

                if .val1 <> undefined and .val2 <> undefined
                    .idx = .idx + 1
                    .data1#[.idx] = .val1
                    .data2#[.idx] = .val2
                endif
            endfor
        endif
        
        .n = .countComplete
        .nExcludedRows = .countExcluded
    endif
endproc


# ============================================================================
# @emlExtractPitchValues
# Extract all voiced F0 values from a Pitch object.
#
# Arguments:
#   pitchId - ID of the Pitch object
#   unit$   - unit for extraction ("Hertz", "semitones re 100 Hz", etc.)
#
# Output:
#   .data#         - voiced values only
#   .times#        - corresponding timestamps
#   .n             - number of voiced frames
#   .nTotal        - total number of frames
#   .nUnvoiced     - number of unvoiced frames
#   .percentVoiced - percentage of voiced frames
# ============================================================================
procedure emlExtractPitchValues: .pitchId, .unit$
    # Initialize outputs
    .n = 0
    .nTotal = 0
    .nUnvoiced = 0
    .percentVoiced = 0
    .data# = zero#(0)
    .times# = zero#(0)
    
    # Select pitch and get frame count
    selectObject: .pitchId
    .nTotal = Get number of frames
    
    if .nTotal = 0
        # Empty Pitch object
        .n = 0
    else
        # First pass: count voiced frames
        .countVoiced = 0
        
        for .frame from 1 to .nTotal
            selectObject: .pitchId
            .t = Get time from frame number: .frame
            selectObject: .pitchId
            .val = Get value at time: .t, .unit$, "linear"
            
            if .val <> undefined
                .countVoiced = .countVoiced + 1
            endif
        endfor
        
        .nUnvoiced = .nTotal - .countVoiced
        
        # Allocate vectors
        if .countVoiced > 0
            .data# = zero#(.countVoiced)
            .times# = zero#(.countVoiced)
            
            # Second pass: populate
            .idx = 0
            for .frame from 1 to .nTotal
                selectObject: .pitchId
                .t = Get time from frame number: .frame
                selectObject: .pitchId
                .val = Get value at time: .t, .unit$, "linear"
                
                if .val <> undefined
                    .idx = .idx + 1
                    .data#[.idx] = .val
                    .times#[.idx] = .t
                endif
            endfor
        endif
        
        .n = .countVoiced
        if .nTotal > 0
            .percentVoiced = (.countVoiced / .nTotal) * 100
        endif
    endif
endproc


# ============================================================================
# @emlExtractFormantValues
# Extract formant frequency values from a Formant object.
#
# Arguments:
#   formantId     - ID of the Formant object
#   formantNumber - which formant (1, 2, 3, etc.)
#   unit$         - unit for extraction ("hertz")
#
# Output:
#   .data#       - frequency values (defined frames only)
#   .times#      - corresponding timestamps
#   .bandwidths# - corresponding bandwidths
#   .n           - number of defined frames
#   .nTotal      - total number of frames
# ============================================================================
procedure emlExtractFormantValues: .formantId, .formantNumber, .unit$
    # Initialize outputs
    .n = 0
    .nTotal = 0
    .data# = zero#(0)
    .times# = zero#(0)
    .bandwidths# = zero#(0)
    
    # Select formant and get frame count
    selectObject: .formantId
    .nTotal = Get number of frames
    
    if .nTotal = 0
        .n = 0
    else
        # First pass: count defined frames
        .countDefined = 0
        
        for .frame from 1 to .nTotal
            selectObject: .formantId
            .t = Get time from frame number: .frame
            selectObject: .formantId
            .val = Get value at time: .formantNumber, .t, .unit$, "linear"
            
            if .val <> undefined
                .countDefined = .countDefined + 1
            endif
        endfor
        
        # Allocate vectors
        if .countDefined > 0
            .data# = zero#(.countDefined)
            .times# = zero#(.countDefined)
            .bandwidths# = zero#(.countDefined)
            
            # Second pass: populate
            .idx = 0
            for .frame from 1 to .nTotal
                selectObject: .formantId
                .t = Get time from frame number: .frame
                selectObject: .formantId
                .val = Get value at time: .formantNumber, .t, .unit$, "linear"
                
                if .val <> undefined
                    .idx = .idx + 1
                    .data#[.idx] = .val
                    .times#[.idx] = .t
                    selectObject: .formantId
                    .bw = Get bandwidth at time: .formantNumber, .t, .unit$, "linear"
                    .bandwidths#[.idx] = .bw
                endif
            endfor
        endif
        
        .n = .countDefined
    endif
endproc


# ============================================================================
# @emlExtractIntensityFrames
# Extract intensity values frame by frame.
#
# Arguments:
#   intensityId - ID of the Intensity object
#
# Output:
#   .data#  - intensity values (dB)
#   .times# - timestamps (from Get time from frame number)
#   .n      - number of frames
#   .nTotal - total number of frames (same as .n; included for interface parity)
# ============================================================================
procedure emlExtractIntensityFrames: .intensityId
    # Initialize outputs
    .n = 0
    .nTotal = 0
    .data# = zero#(0)
    .times# = zero#(0)
    
    # Get frame count directly from Intensity object
    selectObject: .intensityId
    .nTotal = Get number of frames
    
    if .nTotal = 0
        .n = 0
    else
        # Allocate vectors
        .data# = zero#(.nTotal)
        .times# = zero#(.nTotal)
        
        # Extract values using frame queries on the Intensity object
        for .frame from 1 to .nTotal
            selectObject: .intensityId
            .t = Get time from frame number: .frame
            selectObject: .intensityId
            .val = Get value at time: .t, "cubic"
            .data#[.frame] = .val
            .times#[.frame] = .t
        endfor
        
        .n = .nTotal
    endif
endproc


# ============================================================================
# @emlExtractHarmonicityFrames
# Extract HNR values (defined frames only).
#
# Arguments:
#   harmonicityId - ID of the Harmonicity object
#
# Output:
#   .data#      - HNR values (dB)
#   .times#     - timestamps
#   .n          - number of defined frames
#   .nTotal     - total number of frames
#   .nUndefined - number of undefined frames
# ============================================================================
procedure emlExtractHarmonicityFrames: .harmonicityId
    # Initialize outputs
    .n = 0
    .nTotal = 0
    .nUndefined = 0
    .data# = zero#(0)
    .times# = zero#(0)
    
    # Select harmonicity and get frame count
    selectObject: .harmonicityId
    .nTotal = Get number of frames
    
    if .nTotal = 0
        .n = 0
    else
        # First pass: count defined frames
        .countDefined = 0
        
        for .frame from 1 to .nTotal
            selectObject: .harmonicityId
            .t = Get time from frame number: .frame
            selectObject: .harmonicityId
            .val = Get value at time: .t, "cubic"
            
            if .val <> undefined
                .countDefined = .countDefined + 1
            endif
        endfor
        
        .nUndefined = .nTotal - .countDefined
        
        # Allocate vectors
        if .countDefined > 0
            .data# = zero#(.countDefined)
            .times# = zero#(.countDefined)
            
            # Second pass: populate
            .idx = 0
            for .frame from 1 to .nTotal
                selectObject: .harmonicityId
                .t = Get time from frame number: .frame
                selectObject: .harmonicityId
                .val = Get value at time: .t, "cubic"
                
                if .val <> undefined
                    .idx = .idx + 1
                    .data#[.idx] = .val
                    .times#[.idx] = .t
                endif
            endfor
        endif
        
        .n = .countDefined
    endif
endproc


# ============================================================================
# @emlValidateTable
# Validate Table has required columns (space-separated string).
#
# Arguments:
#   tableId          - ID of the Table object
#   requiredColumns$ - space-separated list of required column names
#
# Output:
#   .valid    - 1 if all columns present, 0 otherwise
#   .message$ - lists missing columns if invalid, else ""
#   .nRows    - number of rows in table
#   .nCols    - number of columns in table
# ============================================================================
procedure emlValidateTable: .tableId, .requiredColumns$
    # Initialize outputs
    .valid = 1
    .message$ = ""
    
    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    selectObject: .tableId
    .nCols = Get number of columns
    
    # Get all column names into an array
    for .c from 1 to .nCols
        selectObject: .tableId
        .existingCol$[.c] = Get column label: .c
    endfor
    
    # Parse required columns and check each
    .missingCols$ = ""
    .searchStr$ = .requiredColumns$
    
    # Process space-separated required columns
    while .searchStr$ <> ""
        # Find next space or end of string
        .spacePos = index(.searchStr$, " ")
        
        if .spacePos > 0
            .reqCol$ = left$(.searchStr$, .spacePos - 1)
            .searchStr$ = right$(.searchStr$, length(.searchStr$) - .spacePos)
        else
            .reqCol$ = .searchStr$
            .searchStr$ = ""
        endif
        
        # Skip empty tokens (from multiple spaces)
        if .reqCol$ <> ""
            # Check if this column exists
            .colFound = 0
            for .c from 1 to .nCols
                if .existingCol$[.c] = .reqCol$
                    .colFound = 1
                endif
            endfor
            
            if .colFound = 0
                .valid = 0
                if .missingCols$ = ""
                    .missingCols$ = .reqCol$
                else
                    .missingCols$ = .missingCols$ + ", "
                    .missingCols$ = .missingCols$ + .reqCol$
                endif
            endif
        endif
    endwhile
    
    if .valid = 0
        .message$ = "Missing columns: "
        .message$ = .message$ + .missingCols$
    endif
endproc


# ============================================================================
# @eml_normalizeLabel (internal helper)
# ============================================================================
# Canonical form of a group label for comparison purposes: leading and
# trailing spaces/tabs removed, then lower-cased. Without this, "Male",
# "male" and " Male" are three distinct groups.
#
# Input:
#   .raw$ - the literal label as stored in the Table
#
# Output:
#   .result$ - normalised label
# ============================================================================
procedure eml_normalizeLabel: .raw$
    .result$ = .raw$

    # Strip leading spaces and tabs. Praat's "or" does not short-circuit,
    # so the length test is a separate enclosing "if", not a conjunct.
    .trimming = 1
    while .trimming = 1
        .trimming = 0
        if length (.result$) > 0
            .firstChar$ = left$ (.result$, 1)
            if .firstChar$ = " " or .firstChar$ = tab$
                .result$ = right$ (.result$, length (.result$) - 1)
                .trimming = 1
            endif
        endif
    endwhile

    # Strip trailing spaces and tabs
    .trimming = 1
    while .trimming = 1
        .trimming = 0
        if length (.result$) > 0
            .lastChar$ = right$ (.result$, 1)
            if .lastChar$ = " " or .lastChar$ = tab$
                .result$ = left$ (.result$, length (.result$) - 1)
                .trimming = 1
            endif
        endif
    endwhile

    # Equivalent to lowerCase$(), including for non-ASCII ("ÄÖ" -> "äö").
    #
    # NOT a portability fix: the plugin floors at Praat 6.6.30 (see
    # setup.praat), where lowerCase$() exists. The only reason for the regex
    # form is that the headless sweep harness has to run wherever CI puts it,
    # and this expression has been in Praat far longer. If that stops
    # mattering, lowerCase$() reads better and should come back.
    .result$ = replace_regex$ (.result$, "(.)", "\l\1", 0)
endproc


# ============================================================================
# @eml_strictNumericColumn (internal helper)
# ============================================================================
# Decide whether "Get all numbers in column:" will return the cells' VALUES
# or Praat's alphabetical RANK substitution.
#
# Praat numericises a Table column only when EVERY cell is strictly numeric.
# If one cell is not, the command silently returns each row's alphabetical
# rank instead of its value — a whole column of plausible-looking integers.
# The row filter "self [col] <> undefined" does NOT protect against this,
# because that filter uses lenient coercion (it keeps "1,5", "30%", "1/2",
# "2 3") while the numericiser is strict.
#
# Method: append a NON-INTEGER sentinel to a copy of the table and ask for
# the numbers. Rank substitution can only ever produce integers, so a
# non-integer sentinel coming back intact proves real numericisation. This
# cannot be spoofed, and does not depend on reimplementing Praat's own
# numeric-string grammar in script.
#
# Arguments:
#   .tableId     - ID of the Table object
#   .columnName$ - name of the column to test
#
# Output:
#   .strict      - 1 if the column numericises, 0 if it would return ranks
#   .unreadable  - 1 if a cell is empty or undefined (which makes
#                  "Get all numbers in column:" raise a hard error)
#   .firstBadRow - row of the first empty/undefined cell, else 0
# ============================================================================
procedure eml_strictNumericColumn: .tableId, .columnName$
    .strict = 0
    .unreadable = 0
    .firstBadRow = 0

    selectObject: .tableId
    .nRows = Get number of rows

    if .nRows > 0
        # Empty and undefined cells make the numericiser raise instead of
        # returning ranks, so they have to be found by string scan first.
        #
        # ALL THREE SPELLINGS OF "NOT A VALUE", not two. Praat renders an
        # undefined Table cell as the single character "?" — which is what
        # `To Table: "row"` writes into the row-label column of every
        # converted Matrix — and this scan recognised only "" and
        # "--undefined--". "?" therefore passed the scan, the un-nocheck'd
        # `Get all numbers in column:` below ran on it, and the caller got a
        # native Praat error from inside a probe whose entire job is to
        # answer a question without raising:
        #
        #     Table "eml_numericProbe": the cell in row 1 of column "row"
        #     is undefined.
        #
        # THE MANUFACTURING SITES FILL THOSE CELLS with r1..rn before
        # anything reads them — and
        # that is the right place for it, because a row-label column ought to
        # carry labels. This is the other half: a probe that is handed a cell
        # it cannot read must report `.unreadable`, not raise, whatever
        # produced the cell. Any future caller reaching here with a "?" gets
        # the answer the contract above promises instead of a stack trace.
        for .row from 1 to .nRows
            selectObject: .tableId
            .cell$ = Get value: .row, .columnName$
            if .cell$ = "" or .cell$ = "--undefined--" or .cell$ = "?"
                if .unreadable = 0
                    .unreadable = 1
                    .firstBadRow = .row
                endif
            endif
        endfor

        if .unreadable = 0
            selectObject: .tableId
            .probeId = Copy: "eml_numericProbe"
            Append row
            Set string value: .nRows + 1, .columnName$, "1234567.875"
            .probe# = Get all numbers in column: .columnName$
            if .probe# [.nRows + 1] = 1234567.875
                .strict = 1
            endif
            removeObject: .probeId
        endif
    endif
endproc


# ============================================================================
# @eml_classifyCell (internal helper)
# ============================================================================
# Decide what ONE cell actually is. "Get value:" answers a narrower question
# than a user asks: it returns `undefined` for an empty cell and for the
# string "n/a" alike, and it returns a plausible WRONG NUMBER for "1,5". Three
# different problems, one indistinguishable outcome.
#
# The kinds, and why each is separate:
#
#   0  numeric     the cell reads as the number it looks like
#   1  empty       nothing is there; this is missing data, and the
#                  complete-case convention this plugin applies throughout
#                  is the right treatment for it
#   2  locale      a comma stands where a decimal point belongs. Praat reads
#                  "1,5" as 1 — not a dropped row, a DIFFERENT NUMBER. The
#                  user has the value; it is being discarded or corrupted by
#                  a locale mismatch, and that is recoverable if they are
#                  told. It is not guessed at automatically: "1,234" is 1.234
#                  to a European reader and 1234 to an American one, and this
#                  procedure has no basis to choose.
#   3  unreadable  text that is not a number in any locale. The column is not
#                  a measure, and this is not missing data.
#   4  coerced     reads as a number, but not the one written: "1/2" is 1,
#                  "2 3" is 2, "30%" is 0.3. Silently wrong, like kind 2, but
#                  with no locale story behind it.
#   5  leadingDot  ".5" — a decimal point with no leading zero. Praat does
#                  not read it at all, so it is a dropped row rather than a
#                  wrong value, and the remedy is one character. Separated
#                  from kind 3 for that reason.
#
# Strictness is decided by @eml_strictNumericColumn's sentinel probe, not by
# reimplementing Praat's numeric grammar, and not by number(): number() parses
# a LEADING PREFIX, so number("1.234,5") is 1.234 and a defined result proves
# nothing. Verified against Praat 6.6.30 before this was written.
#
# Arguments:
#   .raw$ - the cell's literal contents
#
# Output:
#   .kind      - 0..5 as above
#   .trimmed$  - .raw$ with surrounding whitespace removed (case preserved)
#   .recovered - for kinds 2 and 5, the value the cell would have once
#                written the way Praat reads numbers; undefined otherwise
# ============================================================================
procedure eml_classifyCell: .raw$
    .kind = 3
    .recovered = undefined

    # eml_normalizeLabel lower-cases as well as trimming, which is wanted for
    # label matching and not wanted here, so trim without it.
    .trimmed$ = .raw$
    .trimming = 1
    while .trimming = 1
        .trimming = 0
        if length (.trimmed$) > 0
            .c1$ = left$ (.trimmed$, 1)
            if .c1$ = " " or .c1$ = tab$
                .trimmed$ = right$ (.trimmed$, length (.trimmed$) - 1)
                .trimming = 1
            endif
        endif
    endwhile
    .trimming = 1
    while .trimming = 1
        .trimming = 0
        if length (.trimmed$) > 0
            .c2$ = right$ (.trimmed$, 1)
            if .c2$ = " " or .c2$ = tab$
                .trimmed$ = left$ (.trimmed$, length (.trimmed$) - 1)
                .trimming = 1
            endif
        endif
    endwhile

    if .trimmed$ = "" or .trimmed$ = "--undefined--"
        .kind = 1
        goto CLASSIFY_DONE
    endif

    # A percent sign is tested BEFORE strictness, because Praat's numericiser
    # accepts "30%" — verified, it passes the sentinel probe — and returns
    # 0.3. Someone writing 30% in a measure column means 30, so the strict
    # verdict is true and useless: the cell reads as a number a hundred times
    # smaller than the one written. That is kind 4 by definition.
    if index (.trimmed$, "%") > 0
        .kind = 4
        goto CLASSIFY_DONE
    endif

    @eml_strictOneCell: .trimmed$
    if eml_strictOneCell.strict = 1
        .kind = 0
        goto CLASSIFY_DONE
    endif

    # A bare leading decimal point is not numeric to Praat, so ".5" is a
    # dropped row and not a wrong value. It is separated from kind 3 because
    # it is unambiguously recoverable and the remedy is one character, where
    # kind 3 means the column is not a measure at all.
    .lead1$ = left$ (.trimmed$, 1)
    .lead2$ = left$ (.trimmed$, 2)
    if .lead1$ = "." or .lead2$ = "-." or .lead2$ = "+."
        @eml_strictOneCell: "0" + .trimmed$
        if eml_strictOneCell.strict = 1
            .kind = 5
            .recovered = number ("0" + .trimmed$)
            goto CLASSIFY_DONE
        endif
        if .lead2$ = "-." or .lead2$ = "+."
            @eml_strictOneCell: .lead1$ + "0"
            ... + right$ (.trimmed$, length (.trimmed$) - 1)
            if eml_strictOneCell.strict = 1
                .kind = 5
                .recovered = number (.lead1$ + "0"
                ... + right$ (.trimmed$, length (.trimmed$) - 1))
                goto CLASSIFY_DONE
            endif
        endif
    endif

    if index (.trimmed$, ",") > 0
        .swapped$ = replace$ (.trimmed$, ",", ".", 0)
        @eml_strictOneCell: .swapped$
        if eml_strictOneCell.strict = 1
            .kind = 2
            .recovered = number (.swapped$)
            goto CLASSIFY_DONE
        endif
    endif

    # Not strictly numeric and not a decimal comma. If Praat still coerces it
    # to something, the row is not dropped — it is silently altered.
    .lenient = number (.trimmed$)
    if .lenient <> undefined
        .kind = 4
    else
        .kind = 3
    endif

    label CLASSIFY_DONE
endproc


# ============================================================================
# @eml_strictOneCell (internal helper)
# Strictness verdict for a single literal, via the same sentinel probe
# @eml_strictNumericColumn uses on a whole column.
# ============================================================================
procedure eml_openColumn: .tableId, .columnName$
    # Decide ONCE per column whether the per-cell classifier is needed. A
    # column that numericises strictly and holds no empty cell cannot hold a
    # bad cell of any kind, so every read from it can go straight through
    # "Get value:". Callers hoist this out of their row loop and pass the
    # answer to @eml_readCell.
    .clean = 0
    selectObject: .tableId
    .rows = Get number of rows
    if .rows > 0
        @eml_strictNumericColumn: .tableId, .columnName$
        if eml_strictNumericColumn.strict = 1
            if eml_strictNumericColumn.unreadable = 0
                .clean = 1
            endif
        endif
    endif
endproc


# ============================================================================
# @eml_readCell (internal helper)
# ============================================================================
# The single numeric read. Returns the cell's value when the cell is strictly
# the number it looks like, and `undefined` otherwise — including for "1,5",
# which "Get value:" would have returned as 1.
#
# Every extraction path in this file reads through here, which is the point:
# the row-wise paths (condition matrices, paired columns) and the column-wise
# paths (single column, group vectors) cannot otherwise be relied on to give
# the same account of the same cell, and before this they did not.
#
# Arguments:
#   .tableId, .row, .columnName$
#   .clean - @eml_openColumn's verdict for this column
#
# Output:
#   .value - the number, or undefined
# ============================================================================
procedure eml_readCell: .tableId, .row, .columnName$, .clean
    selectObject: .tableId
    if .clean = 1
        .value = Get value: .row, .columnName$
    else
        .cell$ = Get value: .row, .columnName$
        @eml_classifyCell: .cell$
        if eml_classifyCell.kind = 0
            .value = number (eml_classifyCell.trimmed$)
        else
            .value = undefined
        endif
        # LEAVE THE CALLER'S TABLE SELECTED. The slow path goes through
        # @eml_strictOneCell, which creates a probe Table and removeObject:s
        # it -- and `removeObject:` leaves NOTHING selected. So on return the
        # next bare Table command in the caller's loop failed with
        #
        #     Error: Command "Get value:" not available for current selection.
        #
        # @emlExtractColumn's loop calls nothing else, so an omission here
        # would not show on that caller. It shows the moment a caller
        # interleaves reads: the draw layer's spaghetti and scatter loops
        # read a value and then an ID or group column, and six disclosure
        # cases die -- all of them dirty-data cases, because a clean column
        # takes the fast path and never gets
        # here.
        #
        # Restored here rather than re-selected at each call site: the entry
        # line already selects .tableId, so a caller is entitled to assume the
        # selection it handed in is the one it gets back, and every future
        # caller would otherwise have to learn this the same way.
        selectObject: .tableId
    endif
endproc


procedure eml_strictOneCell: .literal$
    .strict = 0
    if .literal$ <> ""
        .probe = Create Table with column names: "eml_oneCellProbe", 1, "v"
        Set string value: 1, "v", .literal$
        @eml_strictNumericColumn: .probe, "v"
        .strict = eml_strictNumericColumn.strict
        removeObject: .probe
    endif
endproc


# ============================================================================
# @emlAuditColumn
# ============================================================================
# Classify EVERY cell of a column and report the conditions separately, with
# the first offending row and its literal contents for each. This is the one
# place that decision is made; every caller that needs to describe why rows
# went missing asks here, so a table read row-wise and a table read
# column-wise cannot give different accounts of the same cell.
#
# It does NOT change which rows are analysed. Complete-case with the exclusion
# stated is the convention settled on 21 July and it is not reopened here.
# What changes is that the statement is specific.
#
# Arguments:
#   .tableId     - ID of the Table object
#   .columnName$ - name of the column to audit
#
# Output:
#   .nRows, .nValid, .nEmpty, .nLocale, .nUnreadable, .nCoerced
#   .firstEmptyRow / .firstLocaleRow / .firstUnreadableRow / .firstCoercedRow
#   .firstLocaleValue$ / .firstUnreadableValue$ / .firstCoercedValue$
#   .note$  - user-facing sentences, one per condition present, "" if the
#             column is clean. Callers print it verbatim.
#   .error$ - column not found
# ============================================================================
procedure emlAuditColumn: .tableId, .columnName$
    .nRows = 0
    .nValid = 0
    .nEmpty = 0
    .nLocale = 0
    .nUnreadable = 0
    .nCoerced = 0
    .nLeadingDot = 0
    .firstEmptyRow = 0
    .firstLocaleRow = 0
    .firstUnreadableRow = 0
    .firstCoercedRow = 0
    .firstLeadingDotRow = 0
    .firstLocaleValue$ = ""
    .firstUnreadableValue$ = ""
    .firstCoercedValue$ = ""
    .firstLeadingDotValue$ = ""
    .note$ = ""
    .error$ = ""

    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns

    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .columnName$
            .colExists = 1
        endif
    endfor

    if .colExists = 0
        .error$ = "Column not found: " + .columnName$
        goto AUDIT_DONE
    endif

    # Fast path, for the same reason as in @emlExtractColumn: a column that
    # numericises strictly and has no empty cell is all kind 0, and probing
    # each cell to rediscover that is wasted work on a long table.
    if .nRows > 0
        @eml_strictNumericColumn: .tableId, .columnName$
        if eml_strictNumericColumn.strict = 1
            if eml_strictNumericColumn.unreadable = 0
                .nValid = .nRows
                goto AUDIT_DONE
            endif
        endif
    endif

    for .row from 1 to .nRows
        selectObject: .tableId
        .cell$ = Get value: .row, .columnName$
        @eml_classifyCell: .cell$

        if eml_classifyCell.kind = 0
            .nValid = .nValid + 1
        elsif eml_classifyCell.kind = 1
            .nEmpty = .nEmpty + 1
            if .firstEmptyRow = 0
                .firstEmptyRow = .row
            endif
        elsif eml_classifyCell.kind = 2
            .nLocale = .nLocale + 1
            if .firstLocaleRow = 0
                .firstLocaleRow = .row
                .firstLocaleValue$ = eml_classifyCell.trimmed$
            endif
        elsif eml_classifyCell.kind = 4
            .nCoerced = .nCoerced + 1
            if .firstCoercedRow = 0
                .firstCoercedRow = .row
                .firstCoercedValue$ = eml_classifyCell.trimmed$
            endif
        elsif eml_classifyCell.kind = 5
            .nLeadingDot = .nLeadingDot + 1
            if .firstLeadingDotRow = 0
                .firstLeadingDotRow = .row
                .firstLeadingDotValue$ = eml_classifyCell.trimmed$
            endif
        else
            .nUnreadable = .nUnreadable + 1
            if .firstUnreadableRow = 0
                .firstUnreadableRow = .row
                .firstUnreadableValue$ = eml_classifyCell.trimmed$
            endif
        endif
    endfor

    # --- the note ---
    # Ordered by how much damage the condition does, not by how common it is.
    # A wrong number outranks a missing one: a dropped row shows up in N, a
    # corrupted value does not show up anywhere.
    .sep$ = ""
    if .nLocale > 0
        .note$ = .note$ + .sep$ + string$ (.nLocale)
        ... + " cell(s) use a comma where a decimal point belongs (row "
        ... + string$ (.firstLocaleRow) + ": " + .firstLocaleValue$
        ... + "). Praat reads these as a different number, so they are "
        ... + "excluded rather than guessed at. Replace the commas with "
        ... + "points to use these values."
        .sep$ = " "
    endif
    if .nCoerced > 0
        .note$ = .note$ + .sep$ + string$ (.nCoerced)
        ... + " cell(s) are read as a number other than the one written "
        ... + "(row " + string$ (.firstCoercedRow) + ": "
        ... + .firstCoercedValue$ + "). Excluded."
        .sep$ = " "
    endif
    if .nLeadingDot > 0
        .note$ = .note$ + .sep$ + string$ (.nLeadingDot)
        ... + " cell(s) begin with a bare decimal point (row "
        ... + string$ (.firstLeadingDotRow) + ": "
        ... + .firstLeadingDotValue$ + "). Praat does not read these as "
        ... + "numbers. Write a leading zero to use these values."
        .sep$ = " "
    endif
    # WHAT THIS SENTENCE MAY CLAIM. This path DESCRIBES a column; it does not
    # repair one. It sees a cell it cannot read as a number and excludes it,
    # and that is the entire extent of what it knows. Whether a given token is
    # a placeholder standing in for a value that was never collected, or a
    # note somebody typed into a numeric column, is a question about intent,
    # and nothing on this path inspects intent -- the token is reported as
    # unrecognised and the reader is told what became of the cell.
    if .nUnreadable > 0
        .note$ = .note$ + .sep$ + string$ (.nUnreadable)
        ... + " cell(s) are not numeric in any locale (row "
        ... + string$ (.firstUnreadableRow) + ": "
        ... + .firstUnreadableValue$ + "). Unrecognized nonnumeric token; "
        ... + "excluded."
        .sep$ = " "
    endif
    if .nEmpty > 0
        .note$ = .note$ + .sep$ + string$ (.nEmpty)
        ... + " cell(s) are empty (row " + string$ (.firstEmptyRow)
        ... + " first). Treated as missing data."
        .sep$ = " "
    endif

    label AUDIT_DONE
endproc


# ============================================================================
# @emlValidateNumericColumn
# Validate column exists and contains numeric data.
#
# Checks EVERY row, not a sample. Reports both the lenient verdict (how
# many cells coerce to a number at all) and the strict verdict (whether
# "Get all numbers in column:" would return values or ranks), because the
# two disagree exactly where the silent-corruption bugs live.
#
# Arguments:
#   tableId     - ID of the Table object
#   columnName$ - name of the column to validate
#
# Output:
#   .valid            - 1 if column exists and has numeric data, 0 otherwise
#   .nTotal           - total number of rows
#   .nNumeric         - number of numeric values
#   .nMissing         - number of missing/non-numeric values
#   .message$         - descriptive message about validation result
#   .strictNumeric    - 1 if "Get all numbers in column:" returns values,
#                       0 if it would return alphabetical ranks
#   .firstBadRow      - first row whose literal contents are not strictly
#                       numeric (0 if none)
#   .firstBadValue$   - literal contents of that cell
#   .nCoerced         - cells that coerce to a number but are not strictly
#                       numeric (i.e. silently misread)
#   .coercionWarning$ - user-facing description of the coercion hazards
#                       found, or "" if none
# ============================================================================
procedure emlValidateNumericColumn: .tableId, .columnName$
    # Initialize outputs
    .valid = 0
    .nTotal = 0
    .nNumeric = 0
    .nMissing = 0
    .message$ = ""
    .strictNumeric = 0
    .firstBadRow = 0
    .firstBadValue$ = ""
    .nCoerced = 0
    .coercionWarning$ = ""

    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns

    .nTotal = .nRows

    # Check if column exists
    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .columnName$
            .colExists = 1
        endif
    endfor

    if .colExists = 0
        .valid = 0
        .message$ = "Column not found: "
        .message$ = .message$ + .columnName$
    elsif .nRows = 0
        .valid = 0
        .message$ = "Table is empty"
    else
        # Per-cell pass over EVERY row (no sampling). Two things are
        # counted at once: the lenient verdict (does the cell coerce to a
        # number at all) and the coercion hazards (does the cell coerce to
        # something other than what it looks like).
        .nComma = 0
        .nSlash = 0
        .nInnerSpace = 0
        .nPercent = 0
        .nLeadingDot = 0
        for .row from 1 to .nRows
            selectObject: .tableId
            .val = Get value: .row, .columnName$
            selectObject: .tableId
            .cell$ = Get value: .row, .columnName$

            if .val <> undefined
                .nNumeric = .nNumeric + 1
            else
                .nMissing = .nMissing + 1
            endif

            @eml_normalizeLabel: .cell$
            .trimmed$ = eml_normalizeLabel.result$
            .isHazard = 0
            if .trimmed$ <> ""
                if index (.trimmed$, ",") > 0
                    .nComma = .nComma + 1
                    .isHazard = 1
                endif
                if index (.trimmed$, "/") > 0
                    .nSlash = .nSlash + 1
                    .isHazard = 1
                endif
                if index (.trimmed$, " ") > 0
                    .nInnerSpace = .nInnerSpace + 1
                    .isHazard = 1
                endif
                if index (.trimmed$, "%") > 0
                    .nPercent = .nPercent + 1
                    .isHazard = 1
                endif
                if left$ (.trimmed$, 1) = "."
                    .nLeadingDot = .nLeadingDot + 1
                    .isHazard = 1
                endif
                if left$ (.trimmed$, 2) = "-." or left$ (.trimmed$, 2) = "+."
                    .nLeadingDot = .nLeadingDot + 1
                    .isHazard = 1
                endif
            endif
            if .isHazard = 1
                .nCoerced = .nCoerced + 1
            endif
        endfor

        # Strict verdict: after the rows that do not coerce to a number
        # have been dropped (which is what every extraction path does
        # first), would "Get all numbers in column:" return the remaining
        # VALUES, or Praat's alphabetical RANK substitution? The probe
        # column is given a fixed safe name so a column label containing
        # a space cannot break the probe table's construction.
        .presentTable = Create Table with column names: "eml_presentProbe",
            ... 0, "v"
        .nPresent = 0
        for .row from 1 to .nRows
            selectObject: .tableId
            .val = Get value: .row, .columnName$
            if .val <> undefined
                selectObject: .tableId
                .cell$ = Get value: .row, .columnName$
                selectObject: .presentTable
                Append row
                .nPresent = .nPresent + 1
                Set string value: .nPresent, "v", .cell$
            endif
        endfor
        if .nPresent > 0
            @eml_strictNumericColumn: .presentTable, "v"
            .strictNumeric = eml_strictNumericColumn.strict
        endif
        removeObject: .presentTable

        if .nPresent > 0 and .strictNumeric = 0
            # Locate the first surviving cell that the numericiser
            # rejects, by testing each cell on its own one-row table.
            .searching = 1
            for .row from 1 to .nRows
                if .searching = 1
                    selectObject: .tableId
                    .val = Get value: .row, .columnName$
                    if .val <> undefined
                        selectObject: .tableId
                        .cell$ = Get value: .row, .columnName$
                        .cellTable = Create Table with column names:
                            ... "eml_cellProbe", 1, "v"
                        Set string value: 1, "v", .cell$
                        @eml_strictNumericColumn: .cellTable, "v"
                        .cellStrict = eml_strictNumericColumn.strict
                        removeObject: .cellTable
                        if .cellStrict = 0
                            .firstBadRow = .row
                            .firstBadValue$ = .cell$
                            .searching = 0
                        endif
                    endif
                endif
            endfor
        endif

        # Build the coercion warning. The European decimal comma comes
        # first deliberately: it is the only hazard here that yields a
        # plausible WRONG NUMBER ("1,5" reads as 1) rather than a dropped
        # row, so it is the one that corrupts results silently.
        .warn$ = ""
        .sep$ = ""
        if .nComma > 0
            .commaMsg$ = " cell(s) contain a comma: a European decimal"
            .commaMsg$ = .commaMsg$ + " comma is read as a plain integer"
            .commaMsg$ = .commaMsg$ + " (1,5 becomes 1) — wrong value, not"
            .commaMsg$ = .commaMsg$ + " a dropped row."
            .warn$ = .warn$ + .sep$ + string$ (.nComma) + .commaMsg$
            .sep$ = " "
        endif
        if .nSlash > 0
            .slashMsg$ = " cell(s) contain '/': a fraction is truncated"
            .slashMsg$ = .slashMsg$ + " at the slash (1/2 becomes 1)."
            .warn$ = .warn$ + .sep$ + string$ (.nSlash) + .slashMsg$
            .sep$ = " "
        endif
        if .nInnerSpace > 0
            .spaceMsg$ = " cell(s) contain an internal space: the value is"
            .spaceMsg$ = .spaceMsg$ + " truncated there (2 3 becomes 2)."
            .warn$ = .warn$ + .sep$ + string$ (.nInnerSpace) + .spaceMsg$
            .sep$ = " "
        endif
        if .nPercent > 0
            .pctMsg$ = " cell(s) contain '%': read as a proportion"
            .pctMsg$ = .pctMsg$ + " (30% becomes 0.3)."
            .warn$ = .warn$ + .sep$ + string$ (.nPercent) + .pctMsg$
            .sep$ = " "
        endif
        if .nLeadingDot > 0
            .dotMsg$ = " cell(s) start with a bare decimal point: not"
            .dotMsg$ = .dotMsg$ + " numeric to Praat (.5 is dropped)."
            .warn$ = .warn$ + .sep$ + string$ (.nLeadingDot) + .dotMsg$
            .sep$ = " "
        endif
        .coercionWarning$ = .warn$

        if .nNumeric > 0
            .valid = 1
            if .nMissing > 0
                .message$ = "Column valid with some missing values"
            else
                .message$ = "Column valid, all values numeric"
            endif
        else
            .valid = 0
            .message$ = "Column contains no numeric values"
        endif

        # A column that is not strictly numeric cannot be read with
        # "Get all numbers in column:" at all — say so, loudly, and
        # override the lenient verdict.
        if .nNumeric > 0 and .strictNumeric = 0
            .valid = 0
            .rankMsg$ = "Column is NOT strictly numeric: "
            .rankMsg$ = .rankMsg$ + "'Get all numbers in column:' would "
            .rankMsg$ = .rankMsg$ + "return alphabetical RANKS, not values."
            .rowMsg$ = " First offending row: "
            .rowMsg$ = .rowMsg$ + string$ (.firstBadRow)
            .rowMsg$ = .rowMsg$ + ", contents: ["
            .rowMsg$ = .rowMsg$ + .firstBadValue$ + "]"
            .message$ = .rankMsg$ + .rowMsg$
            if .coercionWarning$ <> ""
                .message$ = .message$ + " " + .coercionWarning$
            endif
        endif
    endif
endproc


# ============================================================================
# @emlTableColumnNames
# Get all column names from a Table.
#
# Arguments:
#   tableId - ID of the Table object
#
# Output:
#   .nCols       - number of columns
#   .name$[1..n] - column names (bracket notation)
# ============================================================================
procedure emlTableColumnNames: .tableId
    # Initialize
    .nCols = 0
    
    # Select table and get column count
    selectObject: .tableId
    .nCols = Get number of columns

    # Pre-initialize the name array to the ACTUAL column count, not a fixed cap
    # of 100, so no stale indexed names persist beyond the real data. (M7)
    for .init from 1 to .nCols
        .name$[.init] = ""
    endfor
    
    # Get each column name
    for .c from 1 to .nCols
        selectObject: .tableId
        .name$[.c] = Get column label: .c
    endfor
endproc


# ────────────────────────────────────────────────────────────────────────────
# @emlColumnIndex: .name$
#
# Position of a column name in the most recent @emlTableColumnNames result,
# or 0 if it is not there.
#
# A wrapper's optionmenu is seeded with an INDEX, but the
# form hands back a NAME. Without this, returning to a form after an error
# reseeds it from the original guess and silently discards what the user
# chose — which makes a Back button worth much less than it looks.
# ────────────────────────────────────────────────────────────────────────────
procedure emlColumnIndex: .name$
    .idx = 0
    for .i from 1 to emlTableColumnNames.nCols
        if .idx = 0 and emlTableColumnNames.name$ [.i] = .name$
            .idx = .i
        endif
    endfor
endproc


# ────────────────────────────────────────────────────────────────────────────
# @emlKeepChoice: .name$, .fallback
#
# The index to seed an optionmenu with next time round: the user's own
# choice when it still resolves, otherwise the original guess. Wrapping the
# 0-check here keeps the call sites to one line and means a column that has
# since been renamed degrades to the guess rather than to index 0, which
# Praat rejects.
# ────────────────────────────────────────────────────────────────────────────
procedure emlKeepChoice: .name$, .fallback
    @emlColumnIndex: .name$
    if emlColumnIndex.idx > 0
        .idx = emlColumnIndex.idx
    else
        .idx = .fallback
    endif
endproc


# Global: group sort order (0 = table/discovery order, 1 = alphabetical).
# Set by graphs UI (eml-graphs-form.praat) or manually before calling.
# Stats wrappers without UI default to 0 (table order).
emlGroupSortAlphabetical = 0

# ============================================================================
# @emlCountGroups
# Discover distinct groups in a column. No group limit.
#
# Arguments:
#   tableId   - ID of the Table object
#   groupCol$ - name of the grouping column
#
# Output:
#   .nGroups           - number of distinct groups
#   .groupLabel$[1..n] - labels (order controlled by
#                        emlGroupSortAlphabetical: 0 = discovery, 1 = alpha)
#                        The label kept is the FIRST literal spelling seen
#                        for that group.
#   .groupNorm$[1..n]  - normalised form of each label (see
#                        @eml_normalizeLabel)
#   .nMerged           - number of distinct literal spellings that were
#                        folded into another group by normalisation
#   .mergeWarning$     - description of what was merged, or ""
#   .nBlankRows        - rows whose group cell is empty or whitespace only.
#                        These are EXCLUDED from the count; see below.
#   .error$            - error message if column not found
#
# Groups are matched on the NORMALISED label (trimmed, case-folded), so
# "Male", "male" and " Male" are one group, not three. The same
# normalisation is applied by @eml_getGroupData and
# @eml_getGroupPairedData, so counting and extraction cannot disagree.
#
# A BLANK GROUP CELL IS MISSING DATA, NOT A CATEGORY (12 Aug 2026).
#
# Until this date a row whose group cell was empty -- or whitespace only,
# which normalises to empty -- became a group of its own, indistinguishable
# from a real level. Every consumer inherited it, and the count is not a
# display detail: it is k in every df, every family size, and every legend.
#
#   - @emlOneWayAnova computes dfBetween = k - 1 and dfWithin = N - k
#   - the post-hoc procedures compute k(k-1)/2 comparisons, so one phantom
#     group at a real k = 3 gives SIX adjusted p-values instead of three,
#     every one of them inflated
#   - @emlRunTwoGroupAnalysis refuses at k > 2 and routes the user to ANOVA,
#     so a single blank cell in a genuine two-group table made the t-test
#     unavailable
#   - the draw layer sizes its palette and legend from k, so the figure grew
#     an unlabelled entry
#
# Under emlGroupSortAlphabetical = 1 the blank also sorted FIRST, taking
# index 1 and shifting every real group's index by one.
#
# The row is now skipped and COUNTED, following the convention this tree
# already uses for excluded rows -- @emlExtractGroupVectors.nExcluded,
# @emlExtractPairedColumns.nExcludedRows, @emlExtractConditionMatrix
# .nExcluded: count in the same pass as the keepers, publish as a named
# output, never abort. What a caller does with it is the caller's business;
# what this procedure must not do is quietly invent a group.
#
# harness/disclosure/probe_exclusion_parity.praat has demonstrated this
# defect since it was written -- "a blank group label is counted as a
# category" -- and nothing consumed the probe, so it stayed demonstrated and
# unfixed.
# ============================================================================
procedure emlCountGroups: .tableId, .groupCol$
    .nGroups = 0
    .error$ = ""
    .nMerged = 0
    .mergeWarning$ = ""
    .nBlankRows = 0

    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns

    # Verify column exists
    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .groupCol$
            .colExists = 1
        endif
    endfor

    if .colExists = 0
        .error$ = "Column not found: " + .groupCol$
    elsif .nRows > 0
        # If alphabetical order requested, sort a copy of the table
        # so that encounter order IS alphabetical order
        if emlGroupSortAlphabetical = 1
            .workId = Copy: "eml_temp_sort"
            Sort rows: .groupCol$
        else
            .workId = .tableId
        endif

        # .nRaw / .rawLabel$[] track the OLD exact-string behaviour so the
        # number of spellings that normalisation folded away can be
        # reported rather than silently absorbed.
        .nRaw = 0

        for .row from 1 to .nRows
            selectObject: .workId
            .grp$ = Get value: .row, .groupCol$
            @eml_normalizeLabel: .grp$
            .grpNorm$ = eml_normalizeLabel.result$

            ; MISSING, NOT A LEVEL. Counted here, in the same pass as the
            ; keepers, and then skipped -- including the raw-spelling tally
            ; below, so a blank is never reported as a merged spelling
            ; either. @eml_normalizeLabel returns "" unchanged and folds
            ; whitespace-only cells to "" as well, so one test catches both.
            if .grpNorm$ = ""
                .nBlankRows = .nBlankRows + 1
                goto NEXT_COUNT_ROW
            endif

            .found = 0
            for .g from 1 to .nGroups
                if .groupNorm$[.g] = .grpNorm$
                    .found = 1
                endif
            endfor

            if .found = 0
                .nGroups = .nGroups + 1
                .groupLabel$[.nGroups] = .grp$
                .groupNorm$[.nGroups] = .grpNorm$
            endif

            .rawFound = 0
            for .r from 1 to .nRaw
                if .rawLabel$[.r] = .grp$
                    .rawFound = 1
                endif
            endfor
            if .rawFound = 0
                .nRaw = .nRaw + 1
                .rawLabel$[.nRaw] = .grp$
            endif

            label NEXT_COUNT_ROW
        endfor

        if emlGroupSortAlphabetical = 1
            removeObject: .workId
        endif

        .nMerged = .nRaw - .nGroups
        if .nMerged > 0
            .mw$ = "Group labels differing only in case or surrounding "
            .mw$ = .mw$ + "whitespace were merged: "
            .mergeWarning$ = .mw$
            .listSep$ = ""
            for .r from 1 to .nRaw
                @eml_normalizeLabel: .rawLabel$[.r]
                .rawNorm$ = eml_normalizeLabel.result$
                for .g from 1 to .nGroups
                    if .groupNorm$[.g] = .rawNorm$
                        if .groupLabel$[.g] <> .rawLabel$[.r]
                            .pair$ = "[" + .rawLabel$[.r] + "] -> ["
                            .pair$ = .pair$ + .groupLabel$[.g] + "]"
                            .mergeWarning$ = .mergeWarning$ + .listSep$
                            .mergeWarning$ = .mergeWarning$ + .pair$
                            .listSep$ = ", "
                        endif
                    endif
                endfor
            endfor
        endif
    endif
endproc


# ============================================================================
# @eml_groupSubset (internal helper)
# ============================================================================
# Extract the rows belonging to one group, matching the group label on its
# normalised form (see @eml_normalizeLabel) so that "Male", "male" and
# " Male" select the same rows that @emlCountGroups counted as one group.
#
# When the request and every cell are already in canonical form,
# normalisation is a no-op and the original single-command C-level
# extraction is used unchanged. Only messy label columns pay for the
# normalising copy, and the copy is always of the table — the caller's
# Table is never modified.
#
# Arguments:
#   .tableId     - ID of the Table object
#   .groupCol$   - grouping column
#   .groupLabel$ - label value to match
#
# Output:
#   .subsetId    - new Table containing only that group's rows. Caller
#                  owns it and must remove it. NOTE: on the normalising
#                  path the group column of the subset holds the
#                  normalised label, not the original spelling.
# ============================================================================
procedure eml_groupSubset: .tableId, .groupCol$, .groupLabel$
    @eml_normalizeLabel: .groupLabel$
    .wantNorm$ = eml_normalizeLabel.result$

    .needNormalize = 0
    if .groupLabel$ <> .wantNorm$
        .needNormalize = 1
    endif

    selectObject: .tableId
    .nRows = Get number of rows

    .row = 1
    while .row <= .nRows and .needNormalize = 0
        selectObject: .tableId
        .cell$ = Get value: .row, .groupCol$
        @eml_normalizeLabel: .cell$
        if .cell$ <> eml_normalizeLabel.result$
            .needNormalize = 1
        endif
        .row = .row + 1
    endwhile

    if .needNormalize = 0
        selectObject: .tableId
        .subsetId = Extract rows where column (text): .groupCol$,
            ... "is equal to", .groupLabel$
    else
        selectObject: .tableId
        .workId = Copy: "eml_groupNorm"
        for .r from 1 to .nRows
            selectObject: .workId
            .cell$ = Get value: .r, .groupCol$
            @eml_normalizeLabel: .cell$
            selectObject: .workId
            Set string value: .r, .groupCol$, eml_normalizeLabel.result$
        endfor
        selectObject: .workId
        .subsetId = Extract rows where column (text): .groupCol$,
            ... "is equal to", .wantNorm$
        removeObject: .workId
    endif
endproc


# ============================================================================
# @eml_getGroupData
# Extract one group's numeric data from a Table. Self-contained:
# filters rows by group label, removes undefined values, returns
# auto-sized vector. No group limit, no shared state.
#
# Arguments:
#   tableId    - ID of the Table object
#   dataCol$   - name of the numeric data column
#   groupCol$  - name of the grouping column
#   groupLabel$ - label value to match
#
# Output:
#   .n      - number of valid (non-undefined) observations
#   .data#  - vector of values
#   .error$ - "" on success
#
# Group rows are selected on the normalised label (see @eml_groupSubset)
# so this agrees with @emlCountGroups.
#
# The surviving column is verified to be strictly numeric before
# "Get all numbers in column:" is called. Without that check Praat
# silently returns each row's alphabetical RANK instead of its value
# whenever one surviving cell is not strictly numeric — and the
# "<> undefined" filter above does not prevent it, because that filter
# uses lenient coercion and keeps cells such as "1,5", "30%" and "1/2".
# ============================================================================
procedure eml_getGroupData: .tableId, .dataCol$, .groupCol$, .groupLabel$
    # NOT "self [col] <> undefined", which is Praat's LENIENT test: it keeps
    # "1,5" (as 1) and "30%" (as 0.3). Survivors of that filter reach the
    # strict numericiser, which rejects them, and the procedure would then
    # call exitScript: — tearing the whole run down from inside a helper,
    # with a message about ranks, because one
    # cell in one group was written in a European locale.
    #
    # @emlExtractColumn now applies exactly the same per-cell classification
    # every other path uses, so the row is dropped for a stated reason and
    # the analysis continues on the rows that are genuinely usable.
    .error$ = ""
    @eml_groupSubset: .tableId, .groupCol$, .groupLabel$
    .tempGroup = eml_groupSubset.subsetId
    @emlExtractColumn: .tempGroup, .dataCol$
    if emlExtractColumn.error$ <> ""
        .error$ = emlExtractColumn.error$
        .n = 0
        .data# = zero# (0)
        .nExcluded = 0
        .note$ = ""
    else
        .n = emlExtractColumn.n
        .data# = emlExtractColumn.data#
        .nExcluded = emlExtractColumn.nUndefined
        .note$ = emlExtractColumn.note$
    endif
    removeObject: .tempGroup
endproc


# ============================================================================
# @eml_getGroupPairedData
# ============================================================================
# Extract two numeric columns for one group, keeping only rows where BOTH
# columns are defined (row-wise complete-case deletion within the group).
# Use this for grouped correlation so X and Y stay row-aligned; extracting
# each column separately with eml_getGroupData would misalign the pairs
# when cells are missing.
#
# Arguments:
#   .tableId    - ID of the Table object
#   .colX$      - first numeric column
#   .colY$      - second numeric column
#   .groupCol$  - grouping column
#   .groupLabel$ - label value to match
#
# Output:
#   .n         - number of complete pairs in the group
#   .nExcluded - group rows dropped for a missing X or Y
#   .dataX#    - aligned X values
#   .dataY#    - aligned Y values
#   .error$    - "" on success
#
# Group rows are selected on the normalised label (see @eml_groupSubset).
# Both surviving columns are verified to be strictly numeric before
# "Get all numbers in column:" is called — see @eml_getGroupData for why
# the "<> undefined" filter is not sufficient protection.
# ============================================================================
procedure eml_getGroupPairedData: .tableId, .colX$, .colY$, .groupCol$, .groupLabel$
    # Same shape as @eml_getGroupData: no lenient row filter and no
    # exitScript: teardown, but @emlExtractPairedColumns,
    # which reads both columns through @eml_readCell.
    .error$ = ""
    @eml_groupSubset: .tableId, .groupCol$, .groupLabel$
    .tempGroup = eml_groupSubset.subsetId
    @emlExtractPairedColumns: .tempGroup, .colX$, .colY$
    if emlExtractPairedColumns.error$ <> ""
        .error$ = emlExtractPairedColumns.error$
        .n = 0
        .dataX# = zero# (0)
        .dataY# = zero# (0)
        .nExcluded = 0
    else
        .n = emlExtractPairedColumns.n
        .dataX# = emlExtractPairedColumns.data1#
        .dataY# = emlExtractPairedColumns.data2#
        .nExcluded = emlExtractPairedColumns.nExcludedRows
    endif
    removeObject: .tempGroup
endproc


# ============================================================================
# @eml_kwScan (internal helper)
# ============================================================================
# Scan a "|"-delimited keyword list against a column name.
# Applies word-boundary check for keywords <= 4 characters to reduce
# false positives (e.g., "id" in "video", "rate" in "moderate").
# Boundary = start of string, or preceded by _, space, or hyphen.
#
# Input:
#   .colName$ — column name to test
#   .kwList$  — "|"-delimited keywords (e.g., "group|condition")
#
# Output:
#   .hit — 1 if any keyword matched with boundary rules, 0 otherwise
# ============================================================================

procedure eml_kwScan: .colName$, .kwList$
    .hit = 0
    .rem$ = .kwList$
    while .rem$ <> "" and .hit = 0
        .pipePos = index (.rem$, "|")
        if .pipePos > 0
            .kw$ = left$ (.rem$, .pipePos - 1)
            .rem$ = right$ (.rem$, length (.rem$) - .pipePos)
        else
            .kw$ = .rem$
            .rem$ = ""
        endif
        if .kw$ <> ""
            .pos = index_caseInsensitive (.colName$, .kw$)
            if .pos > 0
                if length (.kw$) <= 4
                    # Word boundary check for short keywords
                    if .pos = 1
                        .hit = 1
                    else
                        .prev$ = mid$ (.colName$, .pos - 1, 1)
                        if .prev$ = "_" or .prev$ = " " or .prev$ = "-"
                            .hit = 1
                        endif
                    endif
                else
                    .hit = 1
                endif
            endif
        endif
    endwhile
endproc


# ============================================================================
# @emlGuessColumnRoles
# ============================================================================
# Infers column roles from Table column names using weighted keyword
# matching and type detection. Replaces positional guessing for dialog
# default population in the wizard and graph form.
#
# Algorithm (3 passes):
#   Pass 1 — Keyword matching: each column is scored (0-10) for 4 roles
#            (group, data, subject, time) using tiered keyword lists.
#   Pass 2 — Type detection: numeric columns get baseline data score 5,
#            string columns get baseline group score 5.
#   Pass 3 — Global greedy assignment: highest-scoring (column, role)
#            pair assigned first, preventing low-priority roles from
#            stealing high-confidence matches.
#   Post  — Factor assignment for two-way designs.
#   Final — Positional fallback if detection fails.
#
# Calls @emlTableColumnNames internally.
#
# Input:
#   .tableId — ID of the Table object
#
# Output:
#   .groupIdx   — categorical/grouping column (0 if undetected)
#   .dataIdx    — numeric data/value column (0 if undetected)
#   .dataIdx2   — secondary numeric column (0 if < 2 numeric columns;
#                 for paired/correlation dialogs needing two data columns)
#   .subjectIdx — participant/speaker ID column (0 if undetected)
#   .timeIdx    — trial/session/time column (0 if undetected)
#   .factor1Idx — primary factor (= groupIdx, for two-way designs)
#   .factor2Idx — secondary factor (0 if < 2 categorical columns)
#
# Callers use whichever outputs are relevant. If both groupIdx and
# dataIdx are 0 after detection, positional defaults are applied
# (groupIdx=1, dataIdx=min(2, nCols)).
# ============================================================================

procedure emlGuessColumnRoles: .tableId
    .groupIdx = 0
    .dataIdx = 0
    .dataIdx2 = 0
    .subjectIdx = 0
    .timeIdx = 0
    .factor1Idx = 0
    .factor2Idx = 0

    @emlTableColumnNames: .tableId
    .nCols = emlTableColumnNames.nCols

    if .nCols < 1
        goto GUESS_ROLES_DONE
    endif

    # ── PASS 1: Keyword scoring ──────────────────────────────────────
    # Score each column (0-10) for each role. Keywords grouped by
    # weight tier: 10 = unambiguous, 8 = strong, 6 = moderate.

    for .col from 1 to .nCols
        .cn$ = emlTableColumnNames.name$[.col]
        .gS[.col] = 0
        .dS[.col] = 0
        .sS[.col] = 0
        .tS[.col] = 0

        # ── Group score ──

        # Weight 10: unambiguous categorical identifiers
        @eml_kwScan: .cn$, "group|condition|category"
        if eml_kwScan.hit = 1 and .gS[.col] < 10
            .gS[.col] = 10
        endif

        # Weight 8: domain-specific categorical terms
        @eml_kwScan: .cn$, "treatment|species|vowel|phoneme|diagnosis|pathology|severity|consonant|language|dialect"
        if eml_kwScan.hit = 1 and .gS[.col] < 8
            .gS[.col] = 8
        endif

        # Weight 6: general categorical terms
        @eml_kwScan: .cn$, "class|type|sex|gender|style|task|register|ensemble|choir|cohort|genre|mode|status|label|level|setting|location|method|technique|instrument|stimulus|repertoire|voice_type|age_group|section|part|region|site"
        if eml_kwScan.hit = 1 and .gS[.col] < 6
            .gS[.col] = 6
        endif

        # ── Data score ──

        # Weight 10: unambiguous measurement terms
        @eml_kwScan: .cn$, "value|score|measurement|jitter|shimmer"
        if eml_kwScan.hit = 1 and .dS[.col] < 10
            .dS[.col] = 10
        endif

        # Weight 8: acoustic and scientific measures
        @eml_kwScan: .cn$, "intensity|frequency|pitch|duration|hnr|cpps|amplitude|bandwidth|formant|energy|power|contact_quotient"
        if eml_kwScan.hit = 1 and .dS[.col] < 8
            .dS[.col] = 8
        endif

        # Weight 8: short acoustic keywords (boundary-checked)
        @eml_kwScan: .cn$, "f0|f1|f2|f3|f4|cq|cpp"
        if eml_kwScan.hit = 1 and .dS[.col] < 8
            .dS[.col] = 8
        endif

        # Weight 6: general numeric/measurement terms
        @eml_kwScan: .cn$, "mean|rate|ratio|result|outcome|response|rating|measure|percent|proportion|slope|median|average|threshold|alpha_ratio|cog|spectral|harmonic|noise|spl|snr|fraction|extent|area|count|total|period|cycle"
        if eml_kwScan.hit = 1 and .dS[.col] < 6
            .dS[.col] = 6
        endif

        # ── Subject score ──

        # Weight 10: unambiguous participant identifiers
        @eml_kwScan: .cn$, "participant|subject|speaker|singer"
        if eml_kwScan.hit = 1 and .sS[.col] < 10
            .sS[.col] = 10
        endif

        # Weight 8: domain-specific person identifiers
        @eml_kwScan: .cn$, "patient|listener|rater|talker|client|student|evaluator|assessor"
        if eml_kwScan.hit = 1 and .sS[.col] < 8
            .sS[.col] = 8
        endif

        # Weight 6: general person/case terms
        @eml_kwScan: .cn$, "performer|respondent|child|adult|judge"
        if eml_kwScan.hit = 1 and .sS[.col] < 6
            .sS[.col] = 6
        endif

        # Weight 6: short identifier keywords (boundary-checked)
        @eml_kwScan: .cn$, "id"
        if eml_kwScan.hit = 1 and .sS[.col] < 6
            .sS[.col] = 6
        endif

        # ── Time score ──

        # Weight 10: unambiguous temporal/trial identifiers
        @eml_kwScan: .cn$, "trial|session|timepoint|baseline"
        if eml_kwScan.hit = 1 and .tS[.col] < 10
            .tS[.col] = 10
        endif

        # Weight 8: repeated-measures temporal terms
        @eml_kwScan: .cn$, "repetition|block|recording|iteration"
        if eml_kwScan.hit = 1 and .tS[.col] < 8
            .tS[.col] = 8
        endif

        # Weight 6: general temporal/order terms
        @eml_kwScan: .cn$, "visit|phase|wave|attempt|occasion|round|stage"
        if eml_kwScan.hit = 1 and .tS[.col] < 6
            .tS[.col] = 6
        endif

        # Weight 6: short temporal keywords (boundary-checked)
        @eml_kwScan: .cn$, "pre|post|rep|day|week|time|date|take"
        if eml_kwScan.hit = 1 and .tS[.col] < 6
            .tS[.col] = 6
        endif
    endfor

    # ── PASS 2: Type detection ───────────────────────────────────────
    # Numeric columns get baseline data score 5; string columns get
    # baseline group score 5. This ensures type evidence participates
    # in scoring but cannot override strong keyword matches.

    for .col from 1 to .nCols
        .cn$ = emlTableColumnNames.name$[.col]
        selectObject: .tableId
        .nRows = Get number of rows
        if .nRows > 0
            .testVal$ = Get value: 1, .cn$
            .numTest = number (.testVal$)
            if .numTest <> undefined
                # Numeric column: boost data score
                if .dS[.col] < 5
                    .dS[.col] = 5
                endif
            else
                # String column: boost group score
                if .gS[.col] < 5
                    .gS[.col] = 5
                endif
            endif
        endif
    endfor

    # ── PASS 3: Global greedy assignment ─────────────────────────────
    # Find the highest-scoring (column, role) pair globally, assign it,
    # remove both from consideration. Repeat for the three roles a dialog
    # actually consumes: group, data, subject.
    # This prevents low-priority roles from stealing high-confidence
    # matches. E.g., "participant" scores group=6 (via "part") but
    # subject=10 — the subject match wins globally.
    #
    # THE TIME ROLE IS NOT A COMPETITOR IN THIS LOOP, and that is the point:
    # in it, it competes on its own keyword weight rather than on how much
    # anything needs the answer. A column
    # named `repetition_rate` scores time=8 ("repetition") against data=6
    # ("rate"), so the time role won it and the measure role — which every
    # comparison dialog reads — was left to whatever came next.
    #
    # Time is the only one of the four roles that NO dialog consumes, so
    # it is the only one that can safely yield. It is now assigned after
    # group, data and subject have settled, out of whatever is left.

    for .col from 1 to .nCols
        .taken[.col] = 0
    endfor
    .roleDone[1] = 0
    .roleDone[2] = 0
    .roleDone[3] = 0
    .roleDone[4] = 0

    for .assignRound from 1 to 3
        .bestScore = 0
        .bestCol = 0
        .bestRole = 0
        for .col from 1 to .nCols
            if .taken[.col] = 0
                if .roleDone[1] = 0 and .gS[.col] > .bestScore
                    .bestScore = .gS[.col]
                    .bestCol = .col
                    .bestRole = 1
                endif
                if .roleDone[2] = 0 and .dS[.col] > .bestScore
                    .bestScore = .dS[.col]
                    .bestCol = .col
                    .bestRole = 2
                endif
                if .roleDone[3] = 0 and .sS[.col] > .bestScore
                    .bestScore = .sS[.col]
                    .bestCol = .col
                    .bestRole = 3
                endif
            endif
        endfor
        if .bestScore > 0
            .taken[.bestCol] = 1
            .roleDone[.bestRole] = 1
            if .bestRole = 1
                .groupIdx = .bestCol
            elsif .bestRole = 2
                .dataIdx = .bestCol
            elsif .bestRole = 3
                .subjectIdx = .bestCol
            endif
        endif
    endfor

    # ── Time role, assigned last, and yielding ─────────────────
    # Best remaining column with time evidence — subject to the column's
    # time evidence being at least as strong as its measurement evidence.
    #
    # Running last is not on its own enough. On `subject, jitter_pre,
    # jitter_post, HNR_pre, HNR_post` the measure role is filled by
    # `jitter_pre`, which leaves `jitter_post` free at this point, and the
    # weight-6 token `post` would take it for a role nothing reads —
    # stranding the second half of the pair. `jitter_post` scores data=10
    # against time=6, so the second condition is what actually saves it:
    # where a column's own evidence says measurement more loudly than it
    # says time, time does not claim it at all.

    .bestTime = 0
    for .col from 1 to .nCols
        if .taken[.col] = 0 and .tS[.col] > .bestTime
            ... and .tS[.col] >= .dS[.col]
            .bestTime = .tS[.col]
            .timeIdx = .col
        endif
    endfor
    if .timeIdx > 0
        .taken[.timeIdx] = 1
        .roleDone[4] = 1
    endif

    # ── Secondary data column (paired/correlation) ───────────────────
    # Best unassigned column with a data score, for dialogs needing
    # two numeric columns (paired t-test, correlation).
    #
    # On a pre/post table the token that identifies a
    # column as the second half of the pair (`post` in `jitter_post`) is
    # the same token that gives it a time score. Ordering alone does not
    # save it: with `jitter_pre` taken as the measure, `jitter_post` is
    # free when the time role runs, so time still claims it and this scan
    # still skips it — and `Column 2` on Compare paired defaults to a
    # different measure entirely, which computes cleanly and looks like a
    # result. The time column is therefore eligible here, but strictly as
    # a fallback: any genuinely unassigned column with a data score wins
    # first, and time is used only when nothing else is left.

    .bestD2 = 0
    for .col from 1 to .nCols
        if .taken[.col] = 0 and .dS[.col] > .bestD2
            .bestD2 = .dS[.col]
            .dataIdx2 = .col
        endif
    endfor
    if .dataIdx2 = 0 and .timeIdx > 0 and .timeIdx <> .dataIdx
        if .dS[.timeIdx] > 0
            .dataIdx2 = .timeIdx
        endif
    endif
    ; The secondary data column is one of the roles the fallbacks below
    ; cannot see on their own: without this, the group fallback
    ; hands `Compare two groups` the same column that Compare paired is
    ; offering as its Column 2.
    if .dataIdx2 > 0
        .taken[.dataIdx2] = 1
    endif

    # ── Factor assignment (two-way designs) ──────────────────────────
    # factor1 = groupIdx. factor2 = next-best unassigned column with
    # a group-type keyword score > 0.

    if .groupIdx > 0
        .factor1Idx = .groupIdx
        .bestF2 = 0
        for .col from 1 to .nCols
            if .col <> .groupIdx and .col <> .dataIdx
                if .gS[.col] > .bestF2
                    .bestF2 = .gS[.col]
                    .factor2Idx = .col
                endif
            endif
        endfor
    endif

    # ── Fallbacks ────────────────────────────────────────────────────
    # If detection failed for essential roles, apply positional
    # defaults matching the graph form convention (group=1, data=2).

    if .groupIdx = 0 and .dataIdx = 0
        .groupIdx = 1
        .taken[1] = 1
        if .nCols >= 2
            .dataIdx = 2
            .taken[2] = 1
        endif
    elsif .groupIdx = 0
        # Data found but no group — first column no other role holds.
        #
        # NOT `.col <> .dataIdx` alone: that leaves every other role —
        # subject, time, secondary data — invisible, so on a
        # repeated-measures table column 1 comes back as BOTH subjectIdx and
        # groupIdx, and `Compare two groups` on demo_paired defaults its
        # grouping variable to the subject id: 20 groups of n = 1. Consult
        # .taken[], and mark the column taken once it is
        # claimed so nothing downstream can claim it a second time.
        for .col from 1 to .nCols
            if .col <> .dataIdx and .taken[.col] = 0 and .groupIdx = 0
                .groupIdx = .col
                .taken[.col] = 1
            endif
        endfor
        # Every column already carries a role. A duplicated default is bad;
        # no default at all is worse, because the dialog then opens on
        # whatever the form's first entry happens to be. Fall back to the
        # old lenient rule rather than leave the role unfilled.
        if .groupIdx = 0
            for .col from 1 to .nCols
                if .col <> .dataIdx and .groupIdx = 0
                    .groupIdx = .col
                endif
            endfor
        endif
    elsif .dataIdx = 0
        # Group found but no data — same rule, same reason.
        for .col from 1 to .nCols
            if .col <> .groupIdx and .taken[.col] = 0 and .dataIdx = 0
                .dataIdx = .col
                .taken[.col] = 1
            endif
        endfor
        if .dataIdx = 0
            for .col from 1 to .nCols
                if .col <> .groupIdx and .dataIdx = 0
                    .dataIdx = .col
                endif
            endfor
        endif
    endif

    # Ensure factor1 has a value if group was detected
    if .groupIdx > 0 and .factor1Idx = 0
        .factor1Idx = .groupIdx
    endif

    label GUESS_ROLES_DONE
endproc


# ============================================================================
# @emlCheckDataScheme
# ============================================================================
# Audit EVERY column of a Table and produce one consolidated, user-facing
# report of the things that will silently cost the user rows.
#
# @emlAuditColumn has classified cells correctly since the C96 work — locale
# decimal commas, unreadable text, percent-coerced values, leading dots — and
# its .note$ is written to be printed verbatim. But it had exactly one
# consumer, in eml-analysis.praat, so on every other path a column full of
# "1,5" was quietly excluded and the user was told only that n was smaller
# than they expected. This walks the whole table so the disclosure happens
# once, up front, wherever the data enters.
#
# Arguments:
#   .tableId — ID of the Table object
#
# Output:
#   .nIssues        — number of columns with something to report
#   .nLocaleTotal   — cells that look like European decimal commas
#   .report$        — "" when the table is clean; otherwise a printable block
# ============================================================================

procedure emlCheckDataScheme: .tableId
    .nIssues = 0
    .nLocaleTotal = 0
    .report$ = ""

    @emlTableColumnNames: .tableId
    .nCols = emlTableColumnNames.nCols

    for .c from 1 to .nCols
        .col$ = emlTableColumnNames.name$ [.c]
        @emlAuditColumn: .tableId, .col$
        if emlAuditColumn.error$ = "" and emlAuditColumn.note$ <> ""
            # A column of genuine text — a group label, a subject ID — is not
            # a problem and must not be reported as one. Only say something
            # when the column looks numeric in intent: some cells parsed, or
            # some cell carries a decimal comma.
            .looksNumeric = 0
            if emlAuditColumn.nValid > 0
                .looksNumeric = 1
            endif
            if emlAuditColumn.nLocale > 0
                .looksNumeric = 1
            endif
            if .looksNumeric = 1
                .nIssues = .nIssues + 1
                .nLocaleTotal = .nLocaleTotal + emlAuditColumn.nLocale
                .report$ = .report$ + "  Column """ + .col$ + """: "
                ... + emlAuditColumn.note$ + newline$
            endif
        endif
    endfor

    if .nIssues > 0
        .report$ = "DATA CHECK — some cells will be excluded:" + newline$
        ... + .report$
        if .nLocaleTotal > 0
            .report$ = .report$ + newline$
            ... + "  Praat TRUNCATES at a comma: 1,5 reads as 1, and so "
            ... + "does 1,234. There is no" + newline$
            ... + "  thousands-separator reading to fall back on — every "
            ... + "comma cell is wrong," + newline$
            ... + "  whatever it was meant to say, so these cells are "
            ... + "excluded rather than guessed." + newline$
            ... + "  A comma also spoils the column around it: with one "
            ... + "comma cell present," + newline$
            ... + "  Praat's own column queries return alphabetical RANKS "
            ... + "instead of values, so" + newline$
            ... + "  a mean of {70, 80,5, 90} comes back as 2. (This tool "
            ... + "reads cells one at a" + newline$
            ... + "  time and is not affected; anything else touching the "
            ... + "Table is.)" + newline$
            ... + "  Use Check & repair data to fix them, or re-export from "
            ... + "your spreadsheet" + newline$
            ... + "  with an English (United States) locale."
            ... + newline$
        endif
    endif
endproc


# ============================================================================
# @emlCheckSourceFile
# ============================================================================
# Scan a CSV file as TEXT, before or independently of reading it into a Table.
#
# This exists because one class of damage cannot be detected afterwards at
# all. Praat's "Read Table from comma-separated file" silently discards
# RFC 4180 doubled-quote escapes: a field written as "Mezzo ""dramatic"""
# arrives as Mezzo dramatic, with no error and no trace left in the Table for
# any later check to find. Commas inside quotes survive; literal quotes do
# not. Verified on Praat 6.6.30, 6 Aug 2026.
#
# So the only place to catch it is the file itself.
#
# Arguments:
#   .path$ — path to the CSV file
#
# Output:
#   .nIssues    — number of distinct problems found
#   .nEscaped   — occurrences of a doubled quote inside a quoted field
#   .semicolon  — 1 if the file looks semicolon-delimited
#   .report$    — "" when clean; otherwise a printable block
# ============================================================================

procedure emlCheckSourceFile: .path$
    .nIssues = 0
    .nEscaped = 0
    .semicolon = 0
    .report$ = ""

    if not fileReadable (.path$)
        .report$ = ""
        goto SOURCE_CHECK_DONE
    endif

    .text$ = readFile$ (.path$)

    # Doubled quotes. A field that is exactly "" is an ordinary empty quoted
    # field and is fine; a doubled quote with a non-delimiter character beside
    # it is an escape that will be eaten. Counting occurrences that are NOT a
    # bare empty field is enough to raise the flag, and the user is pointed at
    # the character rather than at a row number, because after the read the
    # row numbering has shifted and the number would name the wrong row.
    .rest$ = .text$
    .guard = 0
    while index (.rest$, """""") > 0 and .guard < 10000
        .guard = .guard + 1
        .at = index (.rest$, """""")
        .before$ = ""
        if .at > 1
            .before$ = mid$ (.rest$, .at - 1, 1)
        endif
        .after$ = mid$ (.rest$, .at + 2, 1)
        .isEmptyField = 0
        if (.before$ = "," or .before$ = "" or .before$ = newline$)
        ... and (.after$ = "," or .after$ = "" or .after$ = newline$)
            .isEmptyField = 1
        endif
        if .isEmptyField = 0
            .nEscaped = .nEscaped + 1
        endif
        .rest$ = mid$ (.rest$, .at + 2, 1000000)
    endwhile

    # Semicolon-delimited export, the other half of the European locale
    # problem: the whole file arrives as a single column.
    .firstLine$ = .text$
    if index (.firstLine$, newline$) > 0
        .firstLine$ = left$ (.firstLine$, index (.firstLine$, newline$) - 1)
    endif
    .nSemi = 0
    for .i from 1 to length (.firstLine$)
        if mid$ (.firstLine$, .i, 1) = ";"
            .nSemi = .nSemi + 1
        endif
    endfor
    .nComma = 0
    for .i from 1 to length (.firstLine$)
        if mid$ (.firstLine$, .i, 1) = ","
            .nComma = .nComma + 1
        endif
    endfor
    if .nSemi > .nComma and .nSemi > 0
        .semicolon = 1
    endif

    if .nEscaped > 0
        .nIssues = .nIssues + 1
        .report$ = .report$
        ... + "  This file contains " + string$ (.nEscaped)
        ... + " doubled-quote escape(s) inside quoted fields." + newline$
        ... + "  Praat's CSV reader removes those quotes without warning, so "
        ... + "a label written" + newline$
        ... + "  as ""Mezzo """"dramatic"""""" arrives as Mezzo dramatic. "
        ... + "Nothing downstream can" + newline$
        ... + "  detect this, because no trace of it survives the read."
        ... + newline$
        ... + "  Remove the double quotes from your labels, or replace them "
        ... + "with single" + newline$
        ... + "  quotes, and re-import." + newline$
    endif

    if .semicolon = 1
        .nIssues = .nIssues + 1
        .report$ = .report$
        ... + "  The header line uses semicolons rather than commas. This is "
        ... + "a European-locale" + newline$
        ... + "  export; Praat will read the whole line as one column. "
        ... + "Re-export as comma-" + newline$
        ... + "  separated with an English (United States) locale."
        ... + newline$
    endif

    if .nIssues > 0
        .report$ = "DATA CHECK — this file will not import cleanly:"
        ... + newline$ + .report$
    endif

    label SOURCE_CHECK_DONE
endproc


# ============================================================================
# @emlRepairClassify
# ============================================================================
# Decide whether a single cell has an UNAMBIGUOUS intended value, and what it
# is. Deliberately narrower than @eml_classifyCell: that one describes what
# Praat will do with a cell, this one answers the much stricter question of
# whether we may change it without guessing.
#
# Arguments:
#   .raw$ — the cell's literal contents
#
# Output:
#   .kind   0 nothing to do
#           1 decimal comma      -> .fixed$ has a point
#           2 bare leading point -> .fixed$ has a leading zero
#           3 missing-value placeholder -> caller should write ""
#           4 percent            -> .fixed$ is the literal, caller decides
#   .fixed$ the repaired literal (empty for kind 3)
# ============================================================================

procedure emlRepairClassify: .raw$
    .kind = 0
    .fixed$ = ""
    .s$ = replace_regex$ (.raw$, "^[ \t]+|[ \t]+$", "", 0)
    if .s$ = ""
        goto REPAIR_CLASSIFY_DONE
    endif

    # Placeholder for missing. Case-insensitive, and only these exact tokens:
    # a cell reading "no data recorded" is a note, not a placeholder, and
    # silently blanking it would destroy information.
    .low$ = replace_regex$ (.s$, "([A-Z])", "\l\1", 0)
    if .low$ = "na" or .low$ = "n/a" or .low$ = "n.a." or .low$ = "nan"
    ... or .low$ = "null" or .low$ = "nil" or .low$ = "-" or .low$ = "--"
    ... or .low$ = "." or .low$ = "?" or .low$ = "missing"
        .kind = 3
        goto REPAIR_CLASSIFY_DONE
    endif

    # Percent. Reported, never silently altered: Praat already reads "30%" as
    # 0.3 and does NOT exclude it, so this is the one condition where the
    # default behaviour is a wrong number rather than a missing one.
    if index_regex (.s$, "^-?[0-9]+([.,][0-9]+)?[ ]*%$") > 0
        .kind = 4
        .fixed$ = .s$
        goto REPAIR_CLASSIFY_DONE
    endif

    # Any comma at all. Praat has no thousands separator — number("1,234") is
    # 1 — so every comma cell is broken, and the only question is what the
    # user meant. That is a COLUMN question, not a cell one, so this reports
    # the cell as comma-bearing and @emlCommaColumnMode decides the reading.
    # ("1,234" is not exempted as a thousands separator: Praat does not
    # implement thousands separators in any form.)
    if index (.s$, ",") > 0
        .kind = 1
        .fixed$ = .s$
        goto REPAIR_CLASSIFY_DONE
    endif

    # Bare leading point. Praat reads ".5" as undefined.
    if index_regex (.s$, "^-?\.[0-9]+$") > 0
        .kind = 2
        if left$ (.s$, 1) = "-"
            .fixed$ = "-0" + mid$ (.s$, 2, 1000)
        else
            .fixed$ = "0" + .s$
        endif
        goto REPAIR_CLASSIFY_DONE
    endif

    label REPAIR_CLASSIFY_DONE
endproc


# ============================================================================
# @emlCommaColumnMode
# ============================================================================
# Decide, for a WHOLE column, what its commas mean.
#
# Written 6 August 2026 after the author pointed out that the per-cell rule it
# replaces rested on a convention Praat does not have. The old rule left
# "1,234" alone on the grounds that it was "far more likely a thousands
# separator". Praat has no thousands separator: number("1,234") is 1. It
# truncates at the comma and reports no error.
#
# Measured, same session:
#     number("1,234")     = 1
#     number("1,5")       = 1
#     number("12,345,678")= 12
#     number("1.234,5")   = 1.234
#
# And a comma does not merely spoil its own cell. With {70, "80,5", 90} in a
# column, "Get all numbers in column:" returns 1, 2, 3 — the ALPHABETICAL
# RANKS — and "Get mean:" returns 2 instead of 80.17. One comma anywhere
# silently replaces every value in the column with its rank. (The plugin is
# not exposed to this: @emlOpenColumn probes for it and every extraction path
# goes through @eml_readCell. Anything else touching the Table is exposed.)
#
# So there is no reading under which a comma cell is safe, and "leave it" is
# not a conservative choice — it is a guaranteed-wrong one. What is left is
# the only real question: what did the USER mean. That is answerable from the
# column, not from the cell.
#
# Arguments:
#   .tableId, .columnName$
#
# Output:
#   .mode   0 no commas in this column
#           1 decimal comma      — repair "1,234" to 1.234
#           2 digit grouping     — repair "1,234" to 1234
#           3 ambiguous          — both patterns present, or the only
#                                  evidence is a bare n,nnn; do not repair
#   .nComma       cells containing a comma
#   .nDecimal     cells that can only be a decimal comma  (n,d or n,dd)
#   .nGrouped     cells that can only be digit grouping   (n,nnn,nnn)
#   .nEither      cells consistent with both              (n,nnn)
#   .why$         one sentence naming the evidence, for the user-facing report
# ============================================================================

procedure emlCommaColumnMode: .tableId, .columnName$
    .mode = 0
    .nComma = 0
    .nDecimal = 0
    .nGrouped = 0
    .nEither = 0
    .why$ = ""

    selectObject: .tableId
    .nRows = Get number of rows

    for .r from 1 to .nRows
        selectObject: .tableId
        .cell$ = Get value: .r, .columnName$
        .raw$ = replace_regex$ (.cell$, "^[ \t]+|[ \t]+$", "", 0)
        if index (.raw$, ",") > 0
            .nComma = .nComma + 1
            # Two or more commas can only be grouping: 12,345,678.
            if index_regex (.raw$, "^-?[0-9]{1,3}(,[0-9]{3}){2,}$") > 0
                .nGrouped = .nGrouped + 1
            # Exactly n,nnn is consistent with either reading.
            elsif index_regex (.raw$, "^-?[0-9]{1,3},[0-9]{3}$") > 0
                .nEither = .nEither + 1
            # One comma with one or two trailing digits cannot be grouping.
            elsif index_regex (.raw$, "^-?[0-9]+,[0-9]{1,2}$") > 0
                .nDecimal = .nDecimal + 1
            # Anything else with a comma is not repairable arithmetic.
            endif
        endif
    endfor

    if .nComma = 0
        goto COMMA_MODE_DONE
    endif

    if .nDecimal > 0 and .nGrouped > 0
        .mode = 3
        .why$ = "this column mixes cells that can only be decimal commas "
        ... + "with cells that can only be digit grouping"
    elsif .nDecimal > 0
        .mode = 1
        .why$ = "another cell in this column has a comma followed by one or "
        ... + "two digits, which digit grouping never produces"
    elsif .nGrouped > 0
        .mode = 2
        .why$ = "another cell in this column groups digits in threes more "
        ... + "than once, which a decimal comma never produces"
    else
        .mode = 3
        .why$ = "every comma cell here is of the form n,nnn, which is a "
        ... + "decimal comma and digit grouping written identically"
    endif

    label COMMA_MODE_DONE
endproc


# ============================================================================
# @emlStripHeaderQuotes
# ============================================================================
# Remove surrounding double quotes from every column LABEL of a Table.
#
# WHY THIS EXISTS
#
# Praat's CSV reader strips quotes from data cells but NOT from header cells.
# Verified on 6 August 2026: reading
#
#     "grp","value","label"
#     "A",1.5,"Mezzo"
#
# gives cell values A, 1.5 and Mezzo -- quotes gone -- but columns literally
# named `"grp"`, `"value"`, `"label"`, quotes and all. Every lookup then fails
# with "Data column not found: value" on a file that looks perfectly ordinary
# in a text editor.
#
# This is not a rare edge case. R's write.csv() quotes headers BY DEFAULT, so
# any table exported from R and imported here hits it, as do exports from a
# good deal of other software.
#
# Stripping is safe rather than a judgement call, and the reason is the
# inconsistency above: Praat has already decided that a quoted cell means the
# text inside the quotes. Applying the same rule to the header is restoring
# consistency, not imposing a convention. A column genuinely named with
# literal quote characters could not survive a CSV round trip anyway.
#
# Only a MATCHED leading and trailing quote is removed, and only one layer, so
# a header that is quoted oddly is left alone and reported rather than mangled.
#
# Input:
#   .tableId - ID of the Table object (modified in place)
#
# Output:
#   .nStripped - how many labels changed
#   .report$   - one "old -> new" line per change, empty if none
# ============================================================================
procedure emlStripHeaderQuotes: .tableId
    .nStripped = 0
    .report$ = ""

    selectObject: .tableId
    .nCols = Get number of columns

    for .c from 1 to .nCols
        selectObject: .tableId
        .lab$ = Get column label: .c
        .len = length (.lab$)

        if .len >= 2 and left$ (.lab$, 1) = """" and right$ (.lab$, 1) = """"
            .clean$ = mid$ (.lab$, 2, .len - 2)

            ; An empty result would leave the column unaddressable, which is
            ; worse than the quotes. Leave "" alone.
            if .clean$ <> ""
                selectObject: .tableId
                Set column label (index): .c, .clean$
                .nStripped = .nStripped + 1
                .report$ = .report$ + "  " + .lab$ + "  ->  " + .clean$
                ... + newline$
            endif
        endif
    endfor
endproc


# ============================================================================
# THE RESULT STORE'S DATA FINGERPRINT
# ============================================================================
# Provides: @emlGroupFingerprint, @emlAnalysisFingerprint,
#           @emlFingerprintsAgree,
#           @eml_fpNumber, @eml_fpFoldText, @eml_fpTextHash,
#           @eml_fpValueDigest (internal helpers)
#
# WHAT THIS IS FOR. The result store (docs/RULING_RESULT_STORE.md) lets a
# figure RECEIVE the analysis's result instead of re-running the analysis at
# draw time. A stored result may be consumed by many figures, and stays valid
# until either a result-affecting setting changes or THE DATA CHANGES. This
# module answers the second half: it reduces the data an analysis was
# computed from to one short string, so a later reader can ask "is this still
# the same data?" without keeping a copy of the table.
#
# WHY IT IS PER GROUP LEVEL, AND NOT A COLUMN CHECKSUM. Count, sum, sum of
# squares, min and max of the VALUE COLUMN ALONE are unchanged when two
# values are swapped between two groups: the column's multiset is the same
# and so is every group size. That single edit moves every group mean, every
# pairwise p-value and the omnibus test. A column-level fingerprint holds the
# cache over exactly the mutation that most needs to break it. So the key
# binds the value-to-group PAIRING: the description is taken PER LEVEL, over
# the rows that level actually contributed, and the level identities travel
# with it.
#
# WHY IT IS THE VALUES AND NOT THEIR MOMENTS
#
# The obvious cheap description of a level is a handful of moment aggregates
# — n, sum, sum of squares, min, max. DO NOT USE ONE. The reason is a
# theorem, not a probability:
#
#   PER-LEVEL MOMENT AGGREGATES CANNOT DESCRIBE A MULTISET.
#
# Fixing n, sum, sum of squares, min and max pins four numbers on the n - 2
# interior values of a level, so for n >= 5 a CONTINUUM of different level
# contents satisfies them, and any two points of that continuum are the same
# key. It is a solution manifold and not a hash collision, so nothing about
# it gets rarer if the description is made wider: a sixth or a seventh moment
# only raises the n at which the manifold reappears. Levels of n <= 4 are
# provably safe under five aggregates and no others are, which is not a
# guarantee any analysis can rely on.
#
# The consequences are the ones that matter most. A rearrangement of a
# level's interior that holds those five numbers is available on ordinary
# one-decimal formant data, and it moves a rank test's p across .05, moves a
# post-hoc's adjusted p, moves the level's median by a fifth of its range and
# flips its skewness — all of it invisible to a key made of moments. The same
# hole from other angles: two levels built with matching aggregates are
# interchangeable, so their LABELS can be exchanged, and a change too small
# for a loose quantum can still break every TIE a rank test reads.
#
# So the key COMMITS TO THE VALUES THEMSELVES: a digest over each level's
# quantised, SORTED value list (@eml_fpValueDigest). The values have to be
# sorted anyway, so the cost is nearly nothing, and one construction closes
# ranks, ties and moments together:
#   - the multiset is pinned exactly, so no interior rearrangement survives;
#   - MULTIPLICITY is pinned, which is what a rank test's tie correction
#     reads and what no aggregate records at all;
#   - the digest is a function of the SORTED list, so a within-level row
#     reorder is bit-identical by construction, not merely by luck;
#   - two levels with matching moments now have DIFFERENT digests, so
#     exchanging their labels moves the key.
#
# QUANTISE PER VALUE, NOT PER AGGREGATE. A key that quantises a SUM has to
# leave the quantum loose enough to absorb the last bits of an accumulation —
# several spare digits of a double — and that slack is wide enough to hide a
# change that breaks ties. Here nothing is accumulated: each value is
# quantised on its own and folded in, and a row reorder cannot perturb an
# individual value at all, so the quantum does not have to absorb reordering
# noise and sits at 15 significant digits. 400.00000000001 and 400 are
# different values to this key, which is the correct answer, because they are
# different values to every rank test in the plugin.
#
# WHAT MOVES THE KEY (the requirement, from the ruling):
#   - any single-cell edit to the data column, at constant row count
#   - any single-cell edit to the group column, at constant row count
#   - any row added or removed
#   - any value swapped BETWEEN groups
#   - any rearrangement of a level's values, interior or not
#   - any change to the tie structure within or between levels
# WHAT LEGITIMATELY DOES NOT MOVE IT:
#   - reordering rows within a group (nothing an independent-groups
#     comparison computes depends on it, so the cache holds — this is a
#     requirement, not a concession)
#   - reordering whole groups, and the emlGroupSortAlphabetical display
#     setting, because the level records are emitted in a canonical order
#     of this module's own choosing rather than in discovery order
#
# NOT COVERED, DELIBERATELY, EACH WITH ITS REASON:
#   - A SECOND GROUPING FACTOR. This key describes ONE value column split by
#     ONE group column. @emlTwoWayAnova reads a second factor, and rewriting
#     half the cells of that second factor moves F(group) and its p across
#     .05 without touching either column this key describes. A key that
#     silently describes less than the analysis read is the danger, so the
#     store-facing door is @emlAnalysisFingerprint, which is given the
#     analysis's FULL column list and REFUSES — no key, stated error — when
#     it is handed more columns than this key can describe. Refusing re-runs
#     an analysis; describing less validates a result against data it was
#     never computed from. Whether this grows a two-way composition is a
#     scope question, not a defect; the shape is ready for it (see
#     @emlAnalysisFingerprint).
#   - ROW PAIRING. An independent-groups layout has interchangeable rows
#     within a level. A paired/repeated-measures door does not — which row
#     sits opposite which is part of its data — and a within-subject door
#     joining the store needs pairing IN THE KEY at that moment. Same for the
#     scatter/correlation door: x and y are bound row-wise, and a
#     pair-preserving key needs a cross term that no per-level description of
#     one column can supply. Neither is built here. Give either its own
#     procedure and its own format tag, and route it through
#     @emlAnalysisFingerprint so that the refusal is what happens until then.
#   - COLUMNS THE ANALYSIS DID NOT READ. Adding an unrelated column to the
#     table does not move the key, because it cannot move a result. This is
#     why the analysis must declare what it read: the key cannot tell an
#     unread column from an unnamed one.
#   - A CHANGE OF SPELLING THAT NORMALISATION FOLDS AWAY, when the set of
#     spellings present in that level is unchanged — e.g. a level holding
#     both "Male" and "male" where one cell flips to the other spelling.
#     @emlCountGroups merges those into one level, so no number moves; the
#     printed level label can, because it is the first spelling ENCOUNTERED.
#     The key carries the SET of raw spellings per level, sorted and folded
#     as a SEQUENCE, so introducing or removing a spelling moves it. FOLD A
#     SET WITH A SORT, NOT WITH A SUM. A linear combination of the spellings'
#     hashes is order-independent for the wrong reason and cancels: {aa, AA}
#     and {Aa, aA} sum alike while the level's displayed label — the first
#     spelling encountered — differs. A sorted sequence is order-independent
#     without being linear.
#
# A NOTE FOR WHOEVER PINS THIS. The key carries the table's NAME, so a
# mutation leg that builds its mutant as a SEPARATELY NAMED table goes green
# whatever the content did — the name alone moved it. Every mutation fixture
# must carry the same table name as its control, and the within-group-reorder
# leg (which must HOLD) is the one that catches the mistake, because it is the
# only leg whose expected answer the name can flip. Measured: the first run of
# this module's own probe rig named each mutant after its mutation, and four
# legs passed for that reason rather than for the data.
#
# POST-1.0 CONSUMERS. EMMs, diagnostics and the LMM phases consume the store
# natively, and the recorder's edit tripwire (docs/RULING_RECORDER_ROUNDTRIP)
# consumes THIS machinery to detect a table edited mid-recording. There is
# one fingerprint; nobody builds a second one.
#
# FLOATING POINT — READ THIS BEFORE CHANGING ANYTHING HERE
#
# A fingerprint made of raw doubles compared with "=" is a trap. Two things
# break it: (1) a number arrived at by a different route differs in the last
# bits; (2) any journey through text — a stored result written to disk, a
# fingerprint emitted into a recorded script — re-parses to a double that
# need not be the one that was written.
#
# Both are answered by construction rather than by a tolerance:
#   - THE KEY IS TEXT, AND IS ONLY EVER COMPARED AS TEXT. @emlFingerprintsAgree
#     compares strings. Nothing re-parses a fingerprint into a number, so no
#     text round trip can perturb it. A tolerance-based numeric comparison
#     would be strictly worse: it would have to be loose enough to absorb
#     numerical noise, which is the same width as the data edits the key
#     exists to catch.
#   - EVERY NUMBER IS QUANTISED BEFORE IT BECOMES TEXT, to 15 significant
#     digits in a normalised mantissa/exponent form (@eml_fpNumber), so
#     differences below that relative size are invisible to the key. A double
#     carries about 16 to 17 significant digits; the spare digit or two
#     absorbs re-parsing noise. Measured on Praat 6.6.30: a Table saved as
#     text and read back returns bit-identical doubles, because Praat writes
#     the shortest round-tripping decimal, so the spare digits are headroom
#     rather than a working margin.
#   - NOTHING IS ACCUMULATED. A key built on sums needs each level's values
#     SORTED BEFORE THEY ARE SUMMED so that a reordered sum stays
#     bit-identical, and needs a loose quantum underneath that as a second
#     line of defence. There is no sum here. The values are sorted so that the
#     DIGEST is a function of the multiset rather than of the row order, which
#     is the same requirement met without any arithmetic that could drift.
#
# THE COST OF THE QUANTISATION, STATED. An edit smaller than one part in
# 1e15 of a value does not move the key. On realistic measurement data that
# is below the last bit anyone can measure or type; it is not zero, and a
# caller that needs bit-exactness needs a different instrument. The direction
# of every other design choice here is the safe one: when in doubt the key
# MOVES and the analysis re-runs.
#
# WHAT THE DIGESTS ARE, AND WHAT THEY ARE NOT. Labels, names and value lists
# reach the key as two independent polynomial hashes, over different bases
# and different primes near 2^31, each seeded from a fixed salt — about 62
# bits, written as "<count>_<h1>_<h2>". ONE 31-bit polynomial IS NOT ENOUGH
# HERE, and the margin is not close: a birthday search over a few million
# six-character strings finds a 31-bit collision in seconds on a laptop, and
# a colliding pair renames a whole level with the key unmoved, so a reused
# result prints level names that are not in the table. Two hashes of that
# width put an accidental collision past any plausible number of tables, and
# the salt separates this key's hash from any collision list computed against
# a bare polynomial.
#
# IT IS STILL A HASH, AND THE SALT IS NOT A SECRET. It is in this file. This
# key is tamper-EVIDENCE against accident, drift and recomputation — the
# failure modes a cache actually meets — and not a message authentication
# code against someone who has read the source and wants a collision. Praat
# script has no practical SHA-2. Anyone relying on this against a motivated
# adversary is relying on the wrong instrument; say so rather than widening
# the hash again.
#
# ASCII BY CONSTRUCTION. Labels, table names and column names reach the key
# as a count plus numeric hashes, never as their own text. Three reasons:
# the key crosses file boundaries (the recorder writes it into an emitted
# script) where the house rule is ASCII-only and Praat has a UTF-16 trap; a
# label containing the key's own separators cannot forge a record boundary;
# and the key stays short on a table with many levels. The human-readable
# form is a separate output (.summary$), which is for the Info window and is
# never compared.
# ============================================================================


# ============================================================================
# @eml_fpNumber (internal helper)
# ============================================================================
# Canonical text for one number, at 15 significant digits, in a normalised
# mantissa/exponent form: "1.50000000000000e3" is 1500 — one digit before the
# point and fourteen after it, which is fifteen significant digits. Same
# number in, same text out, always; near-equal numbers that differ below the
# 15th digit give the same text. See FLOATING POINT above for why the key is
# text, and why the quantum sits where it does.
#
# Arguments:
#   .x       - the number
#
# Output:
#   .result$ - canonical text ("und" for undefined, "0" for zero)
# ============================================================================
procedure eml_fpNumber: .x
    .result$ = "und"

    if .x <> undefined
        if .x = 0
            .result$ = "0"
        else
            .sign$ = ""
            if .x < 0
                .sign$ = "-"
            endif
            .a = abs (.x)
            .e = floor (log10 (.a))
            .m = .a / 10 ^ .e

            ; log10 and the division are themselves floating point, so the
            ; mantissa can land just outside [1, 10) at an exact power of
            ; ten. Renormalise rather than trusting it.
            if .m >= 10
                .m = .m / 10
                .e = .e + 1
            endif
            if .m < 1
                .m = .m * 10
                .e = .e - 1
            endif

            ; Round first, THEN carry: a mantissa of 9.999999999999999 rounds
            ; to 10, which must become 1.0 at one exponent higher or the same
            ; magnitude would have two spellings. The scale factor is 1e14 —
            ; a mantissa in [1, 10) times 1e14 is at most 1e15, inside the
            ; 2^53 a double holds exactly, so the rounding is exact.
            .m = round (.m * 1e14) / 1e14
            if .m >= 10
                .m = .m / 10
                .e = .e + 1
            endif

            .result$ = .sign$ + fixed$ (.m, 14) + "e" + string$ (.e)
        endif
    endif
endproc


# ============================================================================
# @eml_fpFoldText (internal helper)
# ============================================================================
# Folds one string into a running pair of polynomial hashes. This is the one
# mixing step in this module: labels, column names and value texts all go
# through it, so there is one thing to reason about and one thing to change.
#
# Two hashes, not one: different bases (1000003, 8191) over different primes
# below 2^31 (2147483647 and 2147483629), giving about 62 bits together. The
# largest intermediate is 2147483646 * 1000003, about 2.15e15 and so inside
# the 2^53 (about 9.0e15) a double holds exactly — the arithmetic is exact,
# and the digest is not itself a rounding question. THAT HEADROOM IS THE
# CONSTRAINT ON THE BASES: raising either base much further silently starts
# rounding, and a hash that rounds is not a hash.
#
# A SALT ALONE DOES NOT SEPARATE A COLLIDING PAIR. Adding a seed to a
# polynomial of fixed base contributes the SAME term to two strings of equal
# length, so a pair that collides without the salt collides with it. What
# separates such a pair is a different base — and what makes the next pair
# expensive to find rather than lucky is having two of them, over different
# moduli, both embedded in the key.
#
# The string's LENGTH is folded in after its characters, so that a sequence
# of strings cannot be re-cut: "ab" then "c" and "a" then "bc" fold apart.
# That is what makes @eml_fpValueDigest's list a list and not a puddle.
#
# Arguments:
#   .h1, .h2 - the running hashes to fold into
#   .s$      - the string to fold
#
# Output:
#   .h1, .h2 - the updated hashes (read as eml_fpFoldText.h1 / .h2)
# ============================================================================
procedure eml_fpFoldText: .h1, .h2, .s$
    .len = length (.s$)

    for .i from 1 to .len
        .c = unicode (mid$ (.s$, .i, 1))
        .h1 = (.h1 * 1000003 + .c + 7) mod 2147483647
        .h2 = (.h2 * 8191 + .c * 31 + 13) mod 2147483629
    endfor

    .h1 = (.h1 * 1000003 + (.len mod 1000000) + 3) mod 2147483647
    .h2 = (.h2 * 8191 + (.len mod 1000000) * 31 + 5) mod 2147483629
endproc


# ============================================================================
# @eml_fpTextHash (internal helper)
# ============================================================================
# Deterministic wide hash of a string, so that labels and names can enter the
# fingerprint without their own text (see ASCII BY CONSTRUCTION above).
#
# Two salted polynomials, about 62 bits — see WHAT THE DIGESTS ARE above for
# why one 31-bit polynomial is not enough for this job. The salt is
# domain-separated from the one @eml_fpValueDigest starts from, so a label
# and a value list can never produce the same digest text.
#
# A whole-level rename rests on this hash alone — a relabelled CELL moves the
# level sizes and value digests as well — so it is the one place where hash
# width is load-bearing rather than belt-and-braces.
#
# Arguments:
#   .s$      - the string
#
# Output:
#   .h1, .h2 - the two hashes
#   .hash    - alias for .h1, kept so older probe rigs still read something
#   .result$ - "<length>_<h1>_<h2>", the form the fingerprint embeds
# ============================================================================
procedure eml_fpTextHash: .s$
    .len = length (.s$)

    @eml_fpFoldText: 1948287391, 1103515245, .s$
    .h1 = eml_fpFoldText.h1
    .h2 = eml_fpFoldText.h2
    .hash = .h1

    .result$ = string$ (.len) + "_" + string$ (.h1) + "_" + string$ (.h2)
endproc


# ============================================================================
# @eml_fpValueDigest (internal helper)
# ============================================================================
# The commitment to a level's values: a digest over the QUANTISED, SORTED
# list. It is deliberately not a set of moments; the reasoning is in WHY IT
# IS THE VALUES AND NOT THEIR MOMENTS above and should be read before this is
# changed to anything cheaper.
#
# Order-independence comes from the SORT, not from the fold: the fold is
# deliberately position-dependent, because a position-independent fold over
# the values (a sum, an xor) is exactly the shape that cannot count a
# multiplicity, and multiplicity is what the rank tests read.
#
# THE CALLER SORTS. The argument must already be sorted ascending; the caller
# has usually just sorted it for another reason, and a second sort inside
# here would hide the requirement rather than enforce it.
#
# Arguments:
#   .v#      - the level's values, ALREADY SORTED ASCENDING
#
# Output:
#   .result$ - "<n>_<h1>_<h2>"
# ============================================================================
procedure eml_fpValueDigest: .v#
    .n = size (.v#)
    .h1 = 743243441
    .h2 = 1266874889

    for .i from 1 to .n
        @eml_fpNumber: .v# [.i]
        @eml_fpFoldText: .h1, .h2, eml_fpNumber.result$
        .h1 = eml_fpFoldText.h1
        .h2 = eml_fpFoldText.h2
    endfor

    .result$ = string$ (.n) + "_" + string$ (.h1) + "_" + string$ (.h2)
endproc


# ============================================================================
# @emlGroupFingerprint
# ============================================================================
# The result store's data key for an independent-groups analysis: ONE value
# column split by ONE group column, and nothing else. Everything above this
# line is about why it is shaped the way it is; read WHY IT IS THE VALUES AND
# NOT THEIR MOMENTS before altering the composition.
#
# CALLERS THAT READ MORE COLUMNS THAN TWO MUST NOT CALL THIS DIRECTLY. Go
# through @emlAnalysisFingerprint, which is handed the analysis's full column
# list and refuses what it cannot describe. This procedure describes exactly
# .dataCol$ and .groupCol$, says so in .covers$, and cannot know what else its
# caller read.
#
# The key describes the data AS THE ANALYSIS SAW IT. Levels come from
# @emlCountGroups and values from @eml_getGroupData, which are the same
# procedures the kernels use, so the same rows are counted, the same blank
# group cells are skipped, the same non-numeric cells are excluded, and the
# same case/whitespace folding of labels applies. A fingerprint built from a
# private reading of the table could hold while the analysis's own view of
# it moved.
#
# Arguments:
#   .tableId   - ID of the Table object
#   .dataCol$  - numeric (dependent) column
#   .groupCol$ - grouping column
#
# Output:
#   .result$   - the fingerprint, or "" if it could not be computed
#   .summary$  - human-readable one-liner, for the Info window; NEVER
#                compared, and not ASCII-guaranteed
#   .covers$   - the columns this key describes, comma-separated. A caller
#                that read anything else has a key that does not describe its
#                own result; that is what @emlAnalysisFingerprint checks.
#   .nLevels   - number of group levels
#   .nUsable   - rows that reached a level with a usable value
#   .nBlank    - rows skipped for a blank group cell
#   .error$    - "" on success, diagnostic otherwise
#
# AN EMPTY .result$ IS NOT A KEY AND MUST NEVER MATCH ONE. When the table
# cannot be read the safe answer is "the data is not what it was", so callers
# re-run. @emlFingerprintsAgree enforces that; do not compare with "=".
#
# FORMAT. The leading tag is a FORMAT VERSION. Change the composition, change
# the tag: a stored key written by an older composition then fails to match
# by construction, which re-runs an analysis, whereas a silent change of
# meaning under an unchanged tag would validate a result against data it was
# never computed from. A key written under any other tag — eGF1 among them —
# cannot compare equal to an eGF2 key, which is the point of the tag.
#
#   eGF2|t=<tableName>|r=<rows>|d=<dataCol>|g=<groupCol>|k=<levels>|b=<blank>
#   then one record per level, in canonical label order:
#   |L=<label>;n=<n>;x=<excluded>;v=<valueDigest>;p=<spellings>
#
# Names and labels are <length>_<h1>_<h2> (@eml_fpTextHash); each level's
# values are <n>_<h1>_<h2> over the sorted quantised list
# (@eml_fpValueDigest); the spelling set is the same digest over that level's
# distinct raw spellings, SORTED. The level records are sorted by normalised
# label, NOT by discovery order, so the key does not move when the display
# order setting does.
# ============================================================================
procedure emlGroupFingerprint: .tableId, .dataCol$, .groupCol$
    .result$ = ""
    .summary$ = ""
    .covers$ = .dataCol$ + "," + .groupCol$
    .nLevels = 0
    .nUsable = 0
    .nBlank = 0
    .error$ = ""

    @emlCountGroups: .tableId, .groupCol$

    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
    elsif emlCountGroups.nGroups < 1
        .error$ = "No group levels found in column: " + .groupCol$
    else
        .nLevels = emlCountGroups.nGroups
        .nBlank = emlCountGroups.nBlankRows
        .nRaw = emlCountGroups.nRaw

        ; @emlCountGroups' outputs live only until it runs again, and
        ; @eml_getGroupData below reaches other procedures that call it.
        ; Copy everything needed FIRST — this is the same trap
        ; @emlBridgeGroupComparison documents at its own top.
        for .gi from 1 to .nLevels
            .norm$[.gi] = emlCountGroups.groupNorm$[.gi]
            .gLabel$[.gi] = emlCountGroups.groupLabel$[.gi]
            .order[.gi] = .gi
        endfor
        for .ri from 1 to .nRaw
            .raw$[.ri] = emlCountGroups.rawLabel$[.ri]
        endfor

        ; Canonical order: by normalised label, so neither discovery order
        ; nor emlGroupSortAlphabetical can move the key. Insertion sort —
        ; k is the number of GROUPS, not of rows.
        for .i from 2 to .nLevels
            .hold = .order[.i]
            .holdNorm$ = .norm$[.hold]
            .j = .i - 1
            .placed = 0
            ; Praat's "and" does not short-circuit, so the bound test cannot
            ; be a conjunct with the comparison it protects — the same rule
            ; @eml_normalizeLabel states above.
            while .placed = 0
                .shift = 0
                if .j >= 1
                    .at = .order[.j]
                    if .norm$[.at] > .holdNorm$
                        .shift = 1
                    endif
                endif
                if .shift = 1
                    .order[.j + 1] = .order[.j]
                    .j = .j - 1
                else
                    .placed = 1
                endif
            endwhile
            .order[.j + 1] = .hold
        endfor

        @eml_fpTextHash: .dataCol$
        .dataKey$ = eml_fpTextHash.result$
        @eml_fpTextHash: .groupCol$
        .groupKey$ = eml_fpTextHash.result$

        selectObject: .tableId
        .tableName$ = selected$ ("Table")
        .nRows = Get number of rows
        @eml_fpTextHash: .tableName$
        .tableKey$ = eml_fpTextHash.result$

        .body$ = "eGF2|t=" + .tableKey$
        ... + "|r=" + string$ (.nRows)
        ... + "|d=" + .dataKey$
        ... + "|g=" + .groupKey$
        ... + "|k=" + string$ (.nLevels)
        ... + "|b=" + string$ (.nBlank)
        .sum$ = ""

        for .oi from 1 to .nLevels
            .gi = .order[.oi]

            @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .gLabel$[.gi]

            if eml_getGroupData.error$ <> "" and .error$ = ""
                .error$ = eml_getGroupData.error$
            endif

            .n = eml_getGroupData.n
            .nExcluded = eml_getGroupData.nExcluded
            .v# = eml_getGroupData.data#
            .nUsable = .nUsable + .n

            if .n > 0
                ; SORTED, THEN COMMITTED TO VALUE BY VALUE. Two rows of one
                ; group exchanged produce the identical sorted list and so
                ; the identical digest — by construction, with no arithmetic
                ; in between that could drift. See FLOATING POINT above.
                .s# = sort# (.v#)
                @eml_fpValueDigest: .s#
                .valText$ = eml_fpValueDigest.result$
            else
                ; An empty level still gets a digest rather than a word, so
                ; that "no usable values" and "a value that hashes oddly"
                ; can never be the same key text.
                @eml_fpValueDigest: zero# (0)
                .valText$ = eml_fpValueDigest.result$
            endif

            ; The distinct raw spellings this level was folded from. They are
            ; SORTED and then folded as a SEQUENCE: order-independent because
            ; sorted, and non-linear because the fold is positional. NOT a
            ; sum of their hashes — a sum is order-independent for the wrong
            ; reason and cancels, so {aa, AA} and {Aa, aA} would be one key
            ; while the level's displayed label differed.
            ;
            ; @emlCountGroups' rawLabel$[] is already deduplicated, so this
            ; is a set and not a bag.
            .nSpell = 0
            for .ri from 1 to .nRaw
                @eml_normalizeLabel: .raw$[.ri]
                if eml_normalizeLabel.result$ = .norm$[.gi]
                    .nSpell = .nSpell + 1
                    .spell$[.nSpell] = .raw$[.ri]
                endif
            endfor

            for .si from 2 to .nSpell
                .holdSpell$ = .spell$[.si]
                .sj = .si - 1
                .spellPlaced = 0
                while .spellPlaced = 0
                    .spellShift = 0
                    if .sj >= 1
                        if .spell$[.sj] > .holdSpell$
                            .spellShift = 1
                        endif
                    endif
                    if .spellShift = 1
                        .spell$[.sj + 1] = .spell$[.sj]
                        .sj = .sj - 1
                    else
                        .spellPlaced = 1
                    endif
                endwhile
                .spell$[.sj + 1] = .holdSpell$
            endfor

            .sh1 = 1583421407
            .sh2 = 1442695041
            for .si from 1 to .nSpell
                @eml_fpFoldText: .sh1, .sh2, .spell$[.si]
                .sh1 = eml_fpFoldText.h1
                .sh2 = eml_fpFoldText.h2
            endfor
            .spellText$ = string$ (.nSpell) + "_" + string$ (.sh1)
            ... + "_" + string$ (.sh2)

            @eml_fpTextHash: .norm$[.gi]
            .body$ = .body$ + "|L=" + eml_fpTextHash.result$
            ... + ";n=" + string$ (.n)
            ... + ";x=" + string$ (.nExcluded)
            ... + ";v=" + .valText$
            ... + ";p=" + .spellText$

            if .oi > 1
                .sum$ = .sum$ + ", "
            endif
            .sum$ = .sum$ + .gLabel$[.gi] + " n=" + string$ (.n)
        endfor

        if .error$ = ""
            .result$ = .body$
            .summary$ = string$ (.nLevels) + " levels of " + .groupCol$
            ... + " on " + .dataCol$ + ": " + .sum$
            if .nBlank > 0
                .summary$ = .summary$ + " (" + string$ (.nBlank)
                ... + " rows skipped: no group)"
            endif
        endif
    endif
endproc


# ============================================================================
# @emlAnalysisFingerprint
# ============================================================================
# THE STORE-FACING DOOR. An analysis asks for a data key by naming EVERY
# column it read, in one comma-separated list, value column first. It gets
# back a key that describes exactly those columns, or no key and a stated
# reason.
#
# WHY THIS EXISTS. @emlGroupFingerprint cannot tell an unread column from an
# unnamed one — nothing in a table says which columns an analysis touched. So
# a two-column key handed to a three-column analysis is silently wrong in the
# most dangerous way available: @emlTwoWayAnova's second factor can be
# rewritten wholesale, moving F(group) and its p across .05, without either
# column the key describes changing at all. No composition can fix that,
# because the omission is in the CALL and not in the arithmetic.
#
# So it is closed at the door: a caller declares every column it read, and a
# declaration this module cannot describe is REFUSED. Refusing costs a
# re-run. Not refusing costs a figure quoting a number computed from data the
# table does not hold.
#
# THE SHAPE IS READY FOR TWO-WAY, AND TWO-WAY IS NOT BUILT. A two-way key
# would key the levels on the CROSS of the factors — one record per design
# cell — under a new format tag, and would land as another branch of the
# .nFactors test below. Whether it is built is a scope question for Ian, not
# a defect in this file; until it is, @emlTwoWayAnova asking for a key gets
# the refusal, which is the correct answer and not a stopgap.
#
# Arguments:
#   .tableId     - ID of the Table object
#   .columnList$ - EVERY column the analysis read, comma-separated, value
#                  column first, then the grouping factor(s). Whitespace
#                  around items is trimmed. Order of the factors is not
#                  significant to the refusal, only their number.
#
# Output:
#   .result$   - the fingerprint, or "" if it could not be computed OR was
#                refused. An empty key never agrees with anything.
#   .summary$  - human-readable one-liner; "" when refused
#   .covers$   - the columns the returned key describes; "" when refused
#   .nLevels, .nUsable, .nBlank - as @emlGroupFingerprint
#   .nFactors  - how many grouping columns were declared
#   .refused   - 1 when a well-formed request was declined because no key in
#                this module can describe it, else 0. A refusal is not a
#                malformed call; .error$ says which it was either way.
#   .error$    - "" on success, diagnostic otherwise
# ============================================================================
procedure emlAnalysisFingerprint: .tableId, .columnList$
    .result$ = ""
    .summary$ = ""
    .covers$ = ""
    .nLevels = 0
    .nUsable = 0
    .nBlank = 0
    .nFactors = 0
    .refused = 0
    .error$ = ""

    ; Split on commas, trimming each item. Praat has no split for strings
    ; that returns a vector of them, so this is done by hand; the list is a
    ; handful of column names, not data.
    .nItems = 0
    .rest$ = .columnList$
    .scanning = 1
    while .scanning = 1
        .at = index (.rest$, ",")
        if .at > 0
            .tok$ = left$ (.rest$, .at - 1)
            .rest$ = right$ (.rest$, length (.rest$) - .at)
        else
            .tok$ = .rest$
            .rest$ = ""
            .scanning = 0
        endif
        ; Trim spaces and tabs at both ends, the same way
        ; @eml_normalizeLabel does, but WITHOUT its case folding: a column
        ; name is matched exactly by every other procedure in this file.
        .trimming = 1
        while .trimming = 1
            .trimming = 0
            if length (.tok$) > 0
                .ch$ = left$ (.tok$, 1)
                if .ch$ = " " or .ch$ = tab$
                    .tok$ = right$ (.tok$, length (.tok$) - 1)
                    .trimming = 1
                endif
            endif
        endwhile
        .trimming = 1
        while .trimming = 1
            .trimming = 0
            if length (.tok$) > 0
                .ch$ = right$ (.tok$, 1)
                if .ch$ = " " or .ch$ = tab$
                    .tok$ = left$ (.tok$, length (.tok$) - 1)
                    .trimming = 1
                endif
            endif
        endwhile
        if .tok$ <> ""
            .nItems = .nItems + 1
            .item$[.nItems] = .tok$
        endif
    endwhile

    .nFactors = .nItems - 1

    if .nItems = 0
        .error$ = "No columns declared: a data key must name every column "
        ... + "the analysis read."
    elsif .nItems = 1
        .error$ = "Only one column declared (" + .item$[1] + "): an "
        ... + "independent-groups key needs a value column and a grouping "
        ... + "column."
    elsif .nItems = 2
        @emlGroupFingerprint: .tableId, .item$[1], .item$[2]
        .result$ = emlGroupFingerprint.result$
        .summary$ = emlGroupFingerprint.summary$
        .covers$ = emlGroupFingerprint.covers$
        .nLevels = emlGroupFingerprint.nLevels
        .nUsable = emlGroupFingerprint.nUsable
        .nBlank = emlGroupFingerprint.nBlank
        .error$ = emlGroupFingerprint.error$
    else
        ; MORE COLUMNS THAN THIS MODULE CAN DESCRIBE. Name them, so the
        ; message says what would have to be built rather than only that
        ; something was refused.
        .refused = 1
        .extra$ = ""
        for .i from 3 to .nItems
            if .i > 3
                .extra$ = .extra$ + ", "
            endif
            .extra$ = .extra$ + .item$[.i]
        endfor
        .error$ = "REFUSED: no data key here describes " + string$ (.nFactors)
        ... + " grouping columns. This module keys ONE value column split by "
        ... + "ONE group column; the analysis also read: " + .extra$
        ... + ". A key that described less than the analysis read would "
        ... + "validate a result against data it was never computed from, so "
        ... + "no key is issued and the analysis re-runs."
    endif
endproc


# ============================================================================
# @emlFingerprintsAgree
# ============================================================================
# The one place two fingerprints are compared. Text equality, never numeric
# equality — see FLOATING POINT at the top of this section.
#
# An empty fingerprint on either side means "not known", and NOT KNOWN NEVER
# AGREES: a result whose key could not be computed, a request that was
# refused, or a store that has never been written, must send the caller back
# to the analysis rather than let a figure quote a number that was computed
# from something else.
#
# THE FORMAT TAG IS PART OF THE TEXT, so two keys written under different
# tags cannot agree even if every other field happens to match. That is
# deliberate and is the whole reason the tag exists.
#
# Arguments:
#   .a$   - one fingerprint
#   .b$   - the other
#
# Output:
#   .same - 1 if both are non-empty and identical, else 0
# ============================================================================
procedure emlFingerprintsAgree: .a$, .b$
    .same = 0

    if .a$ <> "" and .b$ <> ""
        if .a$ = .b$
            .same = 1
        endif
    endif
endproc
