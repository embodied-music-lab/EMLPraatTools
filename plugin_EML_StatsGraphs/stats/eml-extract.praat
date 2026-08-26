# ============================================================================
# EML Stats : Data Extraction Layer
# ============================================================================
# Module: eml-extract.praat
# Version: 2.0
# Date: 26 August 2026
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
#   @emlDataFingerprint, @emlGroupFingerprint,
#   @emlAnalysisFingerprint, @emlFingerprintsAgree,
#   @emlStoreKeyTake, @emlPublishAnalysisResult,
#   @emlStoreIdentityAgrees
#
# The fingerprint doors at the foot of this file are the result store's data
# key (docs/RULING_RESULT_STORE.md, §a). It lives HERE, in the extraction
# layer, and not beside either side of the store, because both sides need it:
# the statistics kernels stamp it onto a published result, and the graphs
# layer's annotation bridge recomputes it at draw time to decide whether that
# result still describes the table in front of it. This module is included
# before both. The key answers "same data, same declared scope?" and nothing
# about the settings a result was computed under; the foot of this file says
# what a stored result carries beside it.
#
# AND THE STORE'S SINGLE WRITE SITE IS BELOW THEM, for the same reason and
# with the same argument written out where it sits: @emlPublishAnalysisResult
# is the only procedure in this plugin that assigns a name beginning
# emlStore, and every door that computes a group comparison calls it. See
# THE RESULT STORE: THE SINGLE WRITE SITE at the foot of this file.
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
# Provides: @emlDataFingerprint, @emlGroupFingerprint,
#           @emlAnalysisFingerprint, @emlFingerprintsAgree,
#           @eml_fpCompose, @eml_fpMix (internal helpers)
#
# WHAT THIS IS FOR. The result store (docs/RULING_RESULT_STORE.md) lets a
# figure RECEIVE the analysis's result instead of re-running the analysis at
# draw time. A stored result may be consumed by many figures, and stays valid
# until either a result-affecting setting changes or THE DATA CHANGES. This
# module answers the second half.
#
# THE CONSTRUCTION, IN ONE SENTENCE. Digest the whole table — the table's
# name, its row and column counts, every column name in order, and the
# content of every cell in row order then column order, exactly as the table
# holds it — and then digest the ANALYSIS SCOPE the key is being taken for,
# which is the column names the caller handed in, folded as the caller wrote
# them.
#
# TWO PROPERTIES, AND THE KEY HAS TO HAVE BOTH:
#
#   CONTENT. Every cell of the table is in the key, including the cells of
#   columns nobody named. An edit anywhere in the table moves every key on
#   that table, so a caller cannot scope its way out of an edit it did not
#   anticipate.
#
#   SCOPE. The declared column names are in the key, so two analyses of ONE
#   unmodified table get two different keys. A store keyed on content alone
#   answers "is this the same data?" and is asked "is this the same result?",
#   which are different questions on a table carrying more than one column
#   anybody could analyse.
#
# NEITHER HALF SUBSTITUTES FOR THE OTHER. Content without scope serves the
# result of one comparison to a figure drawing another. Scope without content
# holds while an undeclared column is rewritten under the result. The two
# failures are independent, so the key carries both terms.
#
# ============================================================================
# THE RULING THIS RESTS ON
# ============================================================================
# docs/RULING_RESULT_STORE.md §a requires table identity, BOTH COLUMN NAMES,
# and content. Ian's ruling of 24 August 2026 relaxes exactly one clause of
# it — that a reorder of rows may hold the cache — and leaves the rest
# standing:
#
#   "Since the result of 'somehow this data changed' is to safely rerun the
#    tests, I am fine with 'any change to the data including reordering of
#    rows' forces the mismatch error and redoing of the stats. Otherwise
#    rebuild as you see fit. Agreed we don't round away machine precision."
#
# ANY CHANGE MOVES THE KEY. A moved key costs a re-run of the analysis, and a
# re-run is correct by definition; a held key that should have moved is a
# figure quoting a number computed from other data. The two failures are not
# comparable, so the construction is allowed to be crude in the safe
# direction and must not be crude in the other.
#
# THE COST OF THAT, STATED PLAINLY. Sorting a table's rows in a spreadsheet,
# renaming a subject, adding an unrelated column, correcting a typo in a
# column the analysis never read — each of these re-runs the analysis. None
# of them changes a printed number. So does asking the same question through
# a door that declares its columns differently: a two-name declaration and a
# one-string declaration of the same two columns are two scopes and two keys.
# This is a deliberate exchange of cache hits for the impossibility of two
# whole classes of stale result.
#
# ============================================================================
# WHY THE SCOPE IS FOLDED VERBATIM AND NOTHING IS PARSED
# ============================================================================
# The scope is the text the caller handed in, folded in the order it was
# handed in, with each item's length folded after its characters. Nothing is
# split on a separator, trimmed, lower-cased, prefix-stripped, deduplicated,
# or resolved against the table.
#
# THAT IS WHAT MAKES THE SCOPE SAFE TO CARRY. A key that parses a declaration
# has to decide what an empty item means, what a "num:" prefix means, and
# what to do with a name that is not a column — and every one of those
# decisions is a way for two different declarations to fold to one key. Folded
# verbatim, "val,grp" and "val,,grp" and "grp,val" are three scopes, because
# they are three strings.
#
# A NAME THAT IS NOT A COLUMN IS NOT RESOLVED, AND NOT REFUSED. It is folded
# like any other text, so it yields its own key — distinguishable from every
# other scope, and equal only to itself. A caller with a typo in a column name
# therefore never gets a false hit; it gets a key that only its own typo
# matches, and any real analysis re-runs. The failure is a permanent cache
# miss, which is the safe direction, and the column names a store displays
# come from the store's own record and not from this key.
#
# WHY THE COLUMN NAMES CANNOT SIMPLY BE READ OFF THE KEY. They reach the key
# through the digest and never as their own characters, so the key can
# DISTINGUISH two scopes and cannot DISCLOSE either. A store that wants to
# print what a result is about records the names itself; see WHAT A STORED
# RESULT NEEDS BESIDES THIS KEY below.
#
# ============================================================================
# THE UNSCOPED KEY, AND HOW IT RELATES TO A SCOPED ONE
# ============================================================================
# @emlDataFingerprint takes a table and nothing else, and is the right door
# for a caller that legitimately keys the whole table without naming any
# analysis — the recorder's edit tripwire, which asks only whether the table
# in front of it is the table it saw, is exactly that caller.
#
# ITS KEY IS THE SCOPED KEY WITH AN EMPTY SCOPE. The three doors share one
# construction: the content fold is identical in all of them, and they differ
# only in how many scope items follow it — none, one, or two. The item COUNT
# is folded before the items, so:
#
#   - an unscoped key never equals a scoped key on the same table. "The whole
#     table, no analysis named" and "the whole table, for this comparison" are
#     different questions, and a store must not answer one with the other;
#   - a one-item scope never equals a two-item scope, whatever the items;
#   - two calls with the same arguments always give the same key.
#
# The three keys on one table therefore agree on their r, c and d prelude and
# part company at the scope. Nothing reads a key apart to exploit that; it is
# stated because the relationship is otherwise invisible.
#
# ============================================================================
# WHAT A STORED RESULT NEEDS BESIDES THIS KEY
# ============================================================================
# THIS KEY IS NOT THE WHOLE VALIDITY TEST, AND A STORE BUILT AS IF IT WERE
# WILL SERVE STALE NUMBERS. The key answers "same data, same declared
# scope?". It says nothing about the settings the result was computed under,
# and the settings move printed numbers. Measured on Praat 6.6.30, on one
# table, with the key byte-identical across each pair:
#
#   - CORRECTION METHOD. The same Dunn post-hoc on the same columns gives
#     p = 0.329830 under holm and p = 0.494744 under bonferroni.
#   - GROUP SORT ORDER. `emlGroupSortAlphabetical` — declared in this file,
#     above @emlCountGroups, and assigned from `config_groupSort` at two
#     sites in graphs/eml-graphs-form.praat — decides whether levels arrive
#     in discovery order or alphabetically. A Tukey comparison of the same
#     two levels reads "Zebra - Alpha = +10.0000" under one and
#     "Alpha - Zebra = -10.0000" under the other: the sign of the difference
#     and the names on the bracket both change.
#
# GROUP SORT ORDER HAS NO DIALOG OF ITS OWN. It is a global set from a graphs
# form control, so it is NOT one of the three result-affecting dialog controls
# the ruling's settings census covers, and a census that enumerates dialog
# controls will not find it. It is result-affecting all the same.
#
# SO A STORED RESULT CARRIES, BESIDE THIS KEY:
#   - the column names, in readable form, because the key distinguishes
#     scopes without disclosing them;
#   - the test type, the correction method, and alpha;
#   - the group sort order in force when the result was computed.
# A reader that checks the key alone has checked the data and the scope, and
# has not checked any of the four.
#
# ============================================================================
# HOW A NUMBER REACHES THE KEY
# ============================================================================
# EVERY CELL IS READ AS TEXT, AND ENTERS THE KEY AS THAT TEXT. No number is
# formatted, rounded or quantised anywhere in this module. There is no
# tolerance and no significant-digit count to get wrong.
#
# THE TEXT IS NOT AN APPROXIMATION OF THE CELL — IT IS THE CELL. A Praat
# Table stores each cell as a string and derives its numeric queries from
# that string. Measured on Praat 6.6.30 (dev/tests/phase2/test-fingerprint
# .praat records the probes):
#
#   - a cell set from a double and read back as text re-parses to a
#     bit-identical double, over 4000 random doubles spanning 1e-30 to 1e30,
#     with no exception;
#   - Praat's own Table statistics agree with that re-parse exactly: for a
#     cell holding 0.1 + 0.2, "Get mean" returns the same double as
#     number (cellText$), which is 0.30000000000000004 and not 0.3;
#   - two doubles ONE ULP apart get different cell texts, over 2000 measured
#     pairs, and so do two doubles 2.25 ulps apart, over another 2000;
#   - the subnormal edge holds: 4.94065645841247e-324, 9.88131291682493e-324
#     and 1.48219693752374e-323 are three different texts for three
#     consecutive doubles.
#
# Praat writes the shortest decimal that re-reads as the same double — 17
# significant digits where 17 are needed, fewer where fewer suffice — so the
# text is a faithful name for the double and distinct doubles get distinct
# names. Reading the text therefore loses nothing that any Praat statistic
# could have seen, and it sidesteps number formatting entirely: no exponent
# is computed, so no exponent can underflow.
#
# THE NON-FINITE CORNER IS ONE STATE, NOT THREE. A Praat number cannot hold
# an infinity for a cell to render ambiguously: every overflow route yields
# Praat's `undefined` at the point of arithmetic, before any Table is
# involved. Measured on 6.6.30, `1e308 * 10`, `-1e308 * 10`, `1e308 + 1e308`
# and `exp (1000)` each test equal to `undefined` as a number, and a cell set
# from any of them holds the text "--undefined--" and reads back as
# `undefined`. So there is one non-finite state, the key sees it as that
# text, and there is no three-way ambiguity between +inf, -inf and undefined
# to exploit — the two infinities are not reachable states of a cell.
#
# ============================================================================
# THE MIXING STEP, AND WHAT IT IS WORTH
# ============================================================================
# The key must be short, so the table's text is reduced by @eml_fpMix. That
# procedure is the whole of the arithmetic in this module, and the property
# it has to have is not width but NONLINEARITY.
#
# WHY. A running polynomial — h = (h * B + c) mod M, however many of them in
# parallel, whatever salt each starts from — has this property: for two
# strings OF EQUAL LENGTH the difference of the digests is a fixed linear
# form in the character differences, with coefficients that depend only on
# position. The salt contributes the same term to both strings and cancels.
# So a difference pattern that collides for one pair of strings collides for
# EVERY pair of strings with that pattern, under every salt, and finding one
# is a short lattice reduction rather than a search. Adding a second and a
# third polynomial adds a second and a third linear constraint, and lattice
# reduction consumes them.
#
# THE FIX IS TO REMOVE THE FIXED COEFFICIENTS, not to add more of them.
# @eml_fpMix carries three 31-bit state words and mixes them so that each
# step's coefficients are themselves functions of the state:
#
#   - the multiplier applied to each word is drawn from ANOTHER word's
#     current value, so the "polynomial" has no fixed base;
#   - a QUADRATIC term, the product of two state-derived quantities, enters
#     the first word every step;
#   - the words feed forward within the step, so the second and third words
#     see the first word's new value.
#
# The consequence is measurable, and the suite measures it: for a fixed
# difference pattern applied to 40 random equal-length strings, the digest
# difference is 40 different values, where a plain polynomial gives one
# value 40 times. The reimplementation named under WHAT THIS IS WORTH below
# carries the same measurement to 4000 strings and gets 4000 different
# values, and finds no two distinct characters that commute, over 400000
# state-and-pair trials.
#
# ONE STEP IS NOT ONE-TO-ONE, AND THE SEPARATION DOES NOT REST ON ITS BEING
# SO. Hold h2 and h3 fixed and write h1 = 46337 * u + r, with r = h1 mod
# 46337 and K = h2 mod 46337. The first word's update is then exactly
#
#     h1' = (46337 * m1) * u + (m1 + K) * r + 1031 * c + 1   mod 2147483647
#
# — an affine form in the two coordinates (u, r) — and the second and third
# words reach h1 only through h1'. The character's contribution 1031 * c is
# the same for every h1, so which h1 differences merge depends on h2 and h3
# alone and not on the character; the length terminator has the same shape,
# so it merges them too. TWO STATES THAT SHARE h2 AND h3 AND DIFFER IN h1 BY
# A MERGING AMOUNT THEREFORE FOLD TO ONE STATE UNDER ANY STRING, THE EMPTY
# STRING INCLUDED, AND NEVER SEPARATE AGAIN.
#
# EVERY (h2, h3) ADMITS SUCH A DIFFERENCE, AND ADMITS ABOUT TWO OF THEM. For
# one (h2, h3) the merging differences are the short vectors of a lattice of
# determinant 2147483647 inside a box of about four times that area, so the
# count is a handful and its median is two — measured at a median of two
# over 4000 sampled pairs, with none of the 4000 admitting no difference at
# all. The set of h1 values reaching one output triple has median size two
# in consequence, measured over the same 4000.
#
# THE SUITE PINS TWO WHOLE SUCH SETS. Under h2 = 1554331573 and
# h3 = 1375090233 the sets are arithmetic progressions of step 24928653.
# dev/tests/phase2/test-fingerprint.praat folds all 66 members of the one
# beginning at h1 = 510355490, and all 71 members of the one beginning at
# h1 = 45710, through @eml_fpMix, and gets one triple from each; it also
# folds the in-range state one step off the end of each progression, which
# does not join it, so each set is pinned at exactly its size.
#
# WHAT THAT COSTS IS NOTHING, AND HERE IS THE ARITHMETIC. Two states merge
# only if their h2 and h3 agree EXACTLY — 62 bits — while h1 differs by one
# of about two amounts out of 2^31. A pair of states meets that at about
# 2^-92, which is no better than the birthday bound the digest already
# carries, so a search for a merge is a search for a collision by another
# name. The separation is carried by the MULTI-STEP nonlinearity above,
# where each step's multipliers are drawn from the other words: two folds
# that have not already agreed do not converge.
#
# WHAT THIS IS WORTH, HONESTLY. This is a home-made mixer. It is not proven
# secure, and Praat script has no SHA-2 to reach for instead. What can be
# said is measured rather than asserted: the digest's collision counts are
# the counts a uniform random function gives — over 3 million equal-length
# numeric strings, truncating the output to 32 bits gives 1025 collisions
# against 1047 expected, and to 40 bits gives 2 against 4.1 expected, while
# the full 93-bit output gives none.
#
# THE COUNTS THIS SUITE CANNOT AFFORD TO RUN COME FROM A REIMPLEMENTATION,
# AND WHAT IS CHECKED IS THE AGREEMENT. Three million folds, and the sampled
# distributions above, are minutes of work outside Praat and hours inside
# it. They are measured in a reimplementation of @eml_fpMix and
# @eml_fpCompose that agrees with the shipped procedures bit for bit: 48
# single-string folds spanning the empty string, non-ASCII text and the
# extremes of all three words, and 200 whole keys through all three doors.
# Every count in this section is either pinned by the suite or comes from
# there.
#
# TWO ATTACKS, TWO COSTS, AND HERE THEY ARE THE SAME COST.
#
#   A COLLISION — any two tables that share a key, neither of them chosen in
#   advance — is a birthday search against 93 bits: about 2^46.5, near
#   enough 1e14 mixing steps.
#
#   A SECOND PREIMAGE — a second table matching ONE key already stored — is
#   NOT 2^93. THE STEP INVERTS EFFICIENTLY. Given an output triple and the
#   character, the multiplier of each of the second and third words is read
#   off the output itself, so h2 and h3 each come back by one modular
#   inverse; h1 then comes back by a scan of the 46337 possible values of r
#   in the affine form above. The scan costs milliseconds and returns about
#   two candidates, the true preimage among them 300 times in 300. Walking
#   the fold backwards costs about what walking it forwards costs, so a
#   second preimage is a MEET-IN-THE-MIDDLE: forward from the start state,
#   backward from the stored digest, and match in the middle at about
#   2^46.5 — the same 1e14 as the collision, and not the 2^93 the digest's
#   width suggests on its own.
#
# WHAT THAT MEANS FOR A STORE. Both attacks cost about 1e14 mixing steps,
# and the meet-in-the-middle wants roughly a petabyte of stored states
# besides, or a memoryless variant that pays for that in time. THE FAILURE
# THIS KEY IS SIZED AGAINST IS NOT AN ATTACK AT ALL: it is a table edited
# between the analysis and the figure that quotes it, by someone who is not
# attacking anything, and both costs are beyond that failure by every margin
# it has. Neither cost is a claim of resistance to someone who IS attacking:
# a home-made mixer with no proof behind it earns no such claim, and 1e14 is
# not a margin to lean on deliberately. A store that needs a guarantee
# against a motivated adversary needs a different instrument, and should say
# so rather than widening this one.
#
# THE EXACT-INTEGER LIMIT IS THE BINDING CONSTRAINT ON EVERY CONSTANT HERE.
# A Praat number is a double, which holds integers exactly to 2^53
# (9007199254740992). Every intermediate in @eml_fpMix is bounded by
# construction: the largest is a 31-bit word times a multiplier under 2^19,
# about 8.4e14, measured at 8.43e14 over random input. Raising any multiplier
# far enough to cross 2^53 would make the arithmetic silently stop being the
# arithmetic written down, and a digest that rounds is not a digest.
#
# ============================================================================
# HOW THE CELLS ARE REACHED
# ============================================================================
# THE TABLE IS COPIED AND ITS COLUMNS ARE RENAMED BY POSITION before any cell
# is read. Praat's "Get value:" addresses a column by LABEL and returns the
# first column carrying that label, so on a table with two columns of the
# same name it reads one of them twice and never reads the other — and a
# change in the column it never reads would not move the key. Renaming the
# copy's columns to c1, c2, ... makes every read positional, so no label can
# be ambiguous and no label needs interpreting. The ORIGINAL labels are read
# off first and are digested as they stand.
#
# The copy is unconditional. A fast path for the common case of unique labels
# would be a second code path guarding a rule, and this module states each
# rule once. The copy is a C-level object copy; measured cost is below the
# noise of the cell reads it protects.
#
# ============================================================================
# WHAT THE KEY CARRIES
# ============================================================================
#   eTF2|r=<rows>|c=<columns>|n=<characters>|s=<scope items>|d=<h1>_<h2>_<h3>
#
# r and c are the table's shape and s is the number of declared scope items,
# written literally because they are small, exact and useful to a reader. n
# is the total number of characters folded into the digest, content and scope
# together, which is an exact non-hash invariant: any edit that changes the
# total length of the text moves the key whatever the digest does. d is the
# digest of, in this order: the format tag, the table's name, the row count,
# the column count, every column label in table order, every cell in row
# order and within a row in column order, then the scope item count and each
# scope item as the caller wrote it.
#
# EACH PIECE'S LENGTH IS FOLDED IN AFTER ITS CHARACTERS, so a sequence of
# pieces cannot be re-cut: "ab" then "c" and "a" then "bc" digest apart. That
# is what lets a cell or a column name containing the key's own separators
# travel safely, and it is why no escaping is needed anywhere. The length
# enters that terminator as length mod 1000003, which holds the guarantee for
# every piece this module folds and stops short of a length guarantee in
# general; THE TERMINATOR SEES THE LENGTH ONLY AS length mod 1000003 under
# @eml_fpMix below says exactly where the line is.
#
# THE LEADING TAG IS A FORMAT VERSION. Change the composition, change the
# tag. A stored key written under any other tag then fails to match by
# construction, which re-runs an analysis, whereas a silent change of meaning
# under an unchanged tag would validate a result against data it was never
# computed from. Keys tagged eGF1, eGF2, eDF1 or eTF1 cannot compare equal to
# an eTF2 key, which is the point of the tag.
#
# THE KEY IS ASCII whatever the table holds, because every piece of text
# reaches it as a digest and never as its own characters. The key crosses
# file boundaries — the recorder writes it into an emitted script — where the
# house rule is ASCII-only and Praat has a UTF-16 trap. The human-readable
# forms are separate outputs (.summary$, .covers$, .scope$), which are for the
# Info window, are not ASCII-guaranteed, and are NEVER compared.
#
# ============================================================================
# WHAT MOVES THE KEY
# ============================================================================
# Every edit to the table: any cell, any row added or removed, any column
# added or removed, any column renamed, any reordering of rows or of columns,
# any change to the table's name that survives Praat's own rewriting of it
# (see A NOTE FOR WHOEVER PINS THIS below). And every change of declared
# scope: a
# different column name, the same names in another order, a different number
# of names, or the same names declared through a different door.
#
# THREE THINGS THE KEY CANNOT SEE, and all three are named rather than
# reasoned away:
#   - THE SETTINGS. Correction method, alpha, test type and group sort order
#     are not inputs to this key and do not move it. See WHAT A STORED RESULT
#     NEEDS BESIDES THIS KEY: they are the store's job, not the key's.
#   - A DIGEST COLLISION. The digest is 93 bits over a table of any size, so
#     two different tables can in principle share a key. What is measured
#     about the cost of finding such a pair is in THE MIXING STEP above.
#   - WHEN THE KEY WAS TAKEN. A key describes the table at the instant it is
#     asked for, and a caller that computes a result, lets the table change,
#     and only then stamps a key has stamped a truthful key on a result the
#     table does not support. Nothing inside this module can detect that:
#     the fault is in the ORDER of the calls, not in the arithmetic. THE RULE
#     THAT CLOSES IT IS THE CALLER'S: take the key in the same pass that reads
#     the data, before anything can touch the table, and stamp that key on the
#     result. This is the one place where a caller can still be wrong, and it
#     is the reason the store must have a single write site.
#
# A NOTE FOR WHOEVER PINS THIS. The key carries the table's NAME, so a
# mutation fixture built as a SEPARATELY NAMED table moves the key on the
# name alone, whatever its content did. Every mutation fixture must carry the
# same table name as its control.
#
# AND THE NAME IN THE KEY IS PRAAT'S OBJECT NAME, NOT THE STRING THE CALLER
# ASKED FOR. It is read with selected$ ("Table"), and Praat rewrites a name
# it will not hold: "a b" becomes "a_b" and "data|1" becomes "data_1", so
# "data|1" and "data_1" are ONE name term and two tables a caller believes
# are named apart are named alike here. THAT IS THE TRAP THIS NOTE EXISTS
# FOR. A fixture whose name differs from its control only in characters
# Praat rewrites carries the control's name term, so it looks like a fixture
# that shares a name correctly while pinning nothing — green for the wrong
# reason. Check the name the object ENDED UP WITH, with selected$ ("Table"),
# and never the name it was asked for. dev/tests/phase2/test-fingerprint.praat
# measures the rewriting and the trap: two tables asked for "data|1" and
# "data_1", holding the same content, come back with one key.
#
# POST-1.0 CONSUMERS. EMMs, diagnostics and the LMM phases consume the store
# natively, and the recorder's edit tripwire (docs/RULING_RECORDER_ROUNDTRIP)
# consumes THIS machinery to detect a table edited mid-recording. There is
# one fingerprint; nobody builds a second one. If a paired or repeated door
# joins the store, row pairing enters the key at that moment — it is carried
# today only because every cell is, in the order the table holds it.
#
# COST, measured on Praat 6.6.30. One C-level table copy, one column rename
# per column, one cell read per cell, one pass over the characters of the
# table's text, and one pass over the characters of the declared scope. The
# scope is two short names; the table is everything else, so the work is
# LINEAR in the number of characters in the table and there is nothing
# quadratic in it — measured at 100, 1000, 2000, 4000 and 8000 rows, where
# each doubling of the rows doubles the time. Figures: 1000 rows x 2 columns
# 0.35 s, 1000 x 3 0.43 s, 2000 x 3 0.90 s, 8000 x 3 3.26 s. The table copy
# is 2 ms on a 4000 x 3 table, about a thousandth of the digest it makes
# positional.
# ============================================================================


# ============================================================================
# @eml_fpMix (internal helper)
# ============================================================================
# Folds one string into a running triple of 31-bit state words. This is the
# only mixing step in this module: the format tag, the table's name, the
# counts, the column labels, every cell and every declared scope item all go
# through it, so there is one thing to reason about and one thing to change.
#
# WHY IT IS SHAPED THIS WAY. See THE MIXING STEP in the section header. In
# short: a running polynomial's digest DIFFERENCE for equal-length strings is
# a fixed linear form in the character differences, which lattice reduction
# solves. Here every multiplier is drawn from the state, and a quadratic term
# in the state enters every step, so there are no fixed coefficients to
# solve for.
#
# THE MODULI are three primes just below 2^31: 2147483647, 2147483629 and
# 2147483587. Together the state is about 93 bits.
#
# THE BOUND ON EVERY INTERMEDIATE is 2^53 = 9007199254740992, the largest
# integer a Praat number holds exactly. Term by term, with h < 2^31:
#   h1 * m1  <  2147483647 * 393217   = 8.45e14
#   q        <  46337 * 46337         = 2.15e9
#   h2 * m2  <  2147483629 * 196621   = 4.22e14
#   h3 * m3  <  2147483587 * 98285    = 2.11e14
#   the h3 cross term < 1000003 * 4093 = 4.09e9
# The largest sum is about 8.5e14, a factor of ten inside the limit. RAISING
# ANY MULTIPLIER BOUND MUST BE CHECKED AGAINST THIS ARITHMETIC; past 2^53 the
# operations silently stop being the ones written here.
#
# EACH CHARACTER ENTERS EVERY WORD INJECTIVELY. Praat code points run to
# 1114111, and 1114111 * 1039 is 1.16e9, below every modulus, so no two
# characters contribute the same amount to any word. THAT IS A STATEMENT
# ABOUT THE CHARACTER TERM AND NOT ABOUT THE STEP: the step itself is not
# one-to-one in its state, and ONE STEP IS NOT ONE-TO-ONE in the section
# header says which states merge, how often, and why it costs nothing.
#
# THE STRING'S LENGTH IS FOLDED IN AFTER ITS CHARACTERS, so a sequence of
# strings cannot be re-cut. That is what makes a cell a cell and not a
# puddle, and it is what lets a cell or a column name carrying the key's own
# separators travel safely.
#
# THE TERMINATOR SEES THE LENGTH ONLY AS length mod 1000003. Every length
# term in it is written (.n mod 1000003), so two pieces whose lengths differ
# by exactly 1000003 — or by any multiple of it — terminate identically, and
# the terminator contributes nothing that tells them apart.
#
# WHAT THAT BUYS AND WHAT IT DOES NOT. It buys the re-cut guarantee for
# every piece this module folds, because a cell, a column label, a table
# name and a scope item are all far shorter than 1000003 characters, and
# inside that range the length term IS the length: no two pieces this module
# can meet are congruent without being equal. It does NOT buy a length
# guarantee in general. Two pieces a million characters apart in length are
# told apart by their CHARACTERS, which run the step a different number of
# times, and not by the terminator. Total length is carried separately and
# exactly by the key's n= field, which is written out in full and is not
# reduced by anything.
#
# Arguments:
#   .h1, .h2, .h3 - the running state to fold into
#   .s$           - the string to fold
#
# Output:
#   .h1, .h2, .h3 - the updated state (read as eml_fpMix.h1 / .h2 / .h3)
#   .n            - the number of characters folded from .s$
# ============================================================================
procedure eml_fpMix: .h1, .h2, .h3, .s$
    .n = length (.s$)

    for .i from 1 to .n
        .c = unicode (mid$ (.s$, .i, 1))

        ; The quadratic term: a product of two state-derived quantities, so
        ; the step is not affine in the state. 46337 squared is 2.15e9.
        .q = (.h1 mod 46337) * (.h2 mod 46337)

        ; Every multiplier is drawn from another word's current value, which
        ; is what leaves the digest difference with no fixed coefficients.
        .m1 = 262147 + (.h3 mod 131071)
        .h1 = (.h1 * .m1 + .q + .c * 1031 + 1) mod 2147483647

        .m2 = 131101 + (.h1 mod 65521)
        .h2 = (.h2 * .m2 + (.h1 mod 1000003) + .c * 1033 + 3) mod 2147483629

        .m3 = 65537 + (.h2 mod 32749)
        .h3 = (.h3 * .m3 + (.h2 mod 1000003) * (.h1 mod 4093) + .c * 1039 + 5)
        ... mod 2147483587
    endfor

    ; The length, folded through the same step so that the terminator is as
    ; well mixed as the characters are.
    .q = (.h1 mod 46337) * (.h2 mod 46337)
    .m1 = 262147 + (.h3 mod 131071)
    .h1 = (.h1 * .m1 + .q + (.n mod 1000003) * 1031 + 7) mod 2147483647

    .m2 = 131101 + (.h1 mod 65521)
    .h2 = (.h2 * .m2 + (.h1 mod 1000003) + (.n mod 1000003) * 1033 + 11)
    ... mod 2147483629

    .m3 = 65537 + (.h2 mod 32749)
    .h3 = (.h3 * .m3 + (.h2 mod 1000003) * (.h1 mod 4093)
    ... + (.n mod 1000003) * 1039 + 13) mod 2147483587
endproc


# ============================================================================
# @eml_fpCompose (internal helper)
# ============================================================================
# THE ONE PLACE A KEY IS BUILT. All three doors call this and differ only in
# how many scope items they pass, so the content fold is the same arithmetic
# on the same bytes whichever door was used, and the scope is the only thing
# that can make two keys on one table differ.
#
# TWO SLOTS, BECAUSE THERE ARE TWO SHAPES OF DECLARATION in this plugin: a
# pair of column names (@emlGroupFingerprint), or one list string the caller
# wrote (@emlAnalysisFingerprint). A door needing three names passes them as
# one string through the list form; nothing here splits that string, so a
# list is one item and a pair is two, and the item count is folded so the two
# can never coincide.
#
# THE SCOPE IS FOLDED AFTER THE CONTENT, and the item count is folded before
# the items. Zero items is therefore a fold of its own and not a no-op, which
# is what keeps an unscoped key distinct from a scoped one.
#
# Arguments:
#   .tableId   - ID of the Table object
#   .nScope    - how many of the scope slots are declared: 0, 1 or 2
#   .scope1$   - the first declared item, folded verbatim
#   .scope2$   - the second declared item, folded verbatim
#
# Output: as @emlDataFingerprint.
# ============================================================================
procedure eml_fpCompose: .tableId, .nScope, .scope1$, .scope2$
    .result$ = ""
    .summary$ = ""
    .covers$ = ""
    .scope$ = ""
    .nRows = 0
    .nCols = 0
    .nChars = 0
    .error$ = ""

    if .tableId <= 0
        .error$ = "No table: a data key needs a Table object, and none was "
        ... + "given. No key is issued and the analysis re-runs."
        goto FP_COMPOSE_DONE
    endif

    selectObject: .tableId
    .tableName$ = selected$ ("Table")
    .nRows = Get number of rows
    .nCols = Get number of columns

    ; The copy exists so that every cell read is POSITIONAL. See HOW THE
    ; CELLS ARE REACHED in the section header: "Get value:" resolves a column
    ; by label and returns the first match, so two columns sharing a label
    ; would leave one of them unread.
    .copy = Copy: "eml_fpScratch"

    for .c from 1 to .nCols
        selectObject: .copy
        .lab$[.c] = Get column label: .c
        if .c > 1
            .covers$ = .covers$ + ","
        endif
        .covers$ = .covers$ + .lab$[.c]
    endfor
    for .c from 1 to .nCols
        selectObject: .copy
        Set column label (index): .c, "c" + string$ (.c)
    endfor

    ; The prelude: the format tag, the table's name, and the shape. Folding
    ; the tag means a future format cannot collide with this one even before
    ; the tag text is compared.
    @eml_fpMix: 1948287391, 1103515245, 1571394749, "eTF2"
    .h1 = eml_fpMix.h1
    .h2 = eml_fpMix.h2
    .h3 = eml_fpMix.h3
    .nChars = eml_fpMix.n

    @eml_fpMix: .h1, .h2, .h3, .tableName$
    .h1 = eml_fpMix.h1
    .h2 = eml_fpMix.h2
    .h3 = eml_fpMix.h3
    .nChars = .nChars + eml_fpMix.n

    @eml_fpMix: .h1, .h2, .h3, string$ (.nRows)
    .h1 = eml_fpMix.h1
    .h2 = eml_fpMix.h2
    .h3 = eml_fpMix.h3
    .nChars = .nChars + eml_fpMix.n

    @eml_fpMix: .h1, .h2, .h3, string$ (.nCols)
    .h1 = eml_fpMix.h1
    .h2 = eml_fpMix.h2
    .h3 = eml_fpMix.h3
    .nChars = .nChars + eml_fpMix.n

    ; The column names, in table order.
    for .c from 1 to .nCols
        @eml_fpMix: .h1, .h2, .h3, .lab$[.c]
        .h1 = eml_fpMix.h1
        .h2 = eml_fpMix.h2
        .h3 = eml_fpMix.h3
        .nChars = .nChars + eml_fpMix.n
    endfor

    ; Every cell, in the order the table holds it. No sort, no normalisation,
    ; no numeric parsing: the cell's text is the cell.
    for .r from 1 to .nRows
        for .c from 1 to .nCols
            selectObject: .copy
            .cell$ = Get value: .r, "c" + string$ (.c)
            @eml_fpMix: .h1, .h2, .h3, .cell$
            .h1 = eml_fpMix.h1
            .h2 = eml_fpMix.h2
            .h3 = eml_fpMix.h3
            .nChars = .nChars + eml_fpMix.n
        endfor
    endfor

    removeObject: .copy
    selectObject: .tableId

    ; The declared scope, verbatim and in the order it was declared. The
    ; count first, so that no scope of one length can fold like a scope of
    ; another; then each item, whose own length @eml_fpMix folds after its
    ; characters, so no two items can be re-cut into two others.
    @eml_fpMix: .h1, .h2, .h3, string$ (.nScope)
    .h1 = eml_fpMix.h1
    .h2 = eml_fpMix.h2
    .h3 = eml_fpMix.h3
    .nChars = .nChars + eml_fpMix.n

    if .nScope >= 1
        @eml_fpMix: .h1, .h2, .h3, .scope1$
        .h1 = eml_fpMix.h1
        .h2 = eml_fpMix.h2
        .h3 = eml_fpMix.h3
        .nChars = .nChars + eml_fpMix.n
        .scope$ = .scope1$
    endif
    if .nScope >= 2
        @eml_fpMix: .h1, .h2, .h3, .scope2$
        .h1 = eml_fpMix.h1
        .h2 = eml_fpMix.h2
        .h3 = eml_fpMix.h3
        .nChars = .nChars + eml_fpMix.n
        .scope$ = .scope$ + " ~ " + .scope2$
    endif

    .result$ = "eTF2|r=" + string$ (.nRows)
    ... + "|c=" + string$ (.nCols)
    ... + "|n=" + string$ (.nChars)
    ... + "|s=" + string$ (.nScope)
    ... + "|d=" + string$ (.h1) + "_" + string$ (.h2) + "_" + string$ (.h3)

    .summary$ = "the whole of " + .tableName$ + ": " + string$ (.nRows)
    ... + " rows x " + string$ (.nCols) + " columns (" + .covers$ + ")"
    if .nScope = 0
        .summary$ = .summary$ + ", no analysis named"
    else
        .summary$ = .summary$ + ", for " + .scope$
    endif

    label FP_COMPOSE_DONE
endproc


# ============================================================================
# @emlDataFingerprint
# ============================================================================
# THE UNSCOPED DOOR. Hand it a Table; it returns a key describing the whole of
# that table and naming no analysis. It is the right door for a caller that
# asks only "is the table in front of me the table I saw?" — the recorder's
# edit tripwire is that caller.
#
# A CALLER THAT IS KEYING AN ANALYSIS WANTS @emlGroupFingerprint OR
# @emlAnalysisFingerprint. This key does not distinguish two analyses of one
# table, because it is told about neither; the scoped doors are told, and do.
# The key here is the scoped key with an empty scope, so it never compares
# equal to a scoped key on the same table.
#
# Arguments:
#   .tableId   - ID of the Table object
#
# Output:
#   .result$   - the fingerprint, or "" if no table was given
#   .summary$  - human-readable one-liner, for the Info window; NEVER
#                compared, and not ASCII-guaranteed
#   .covers$   - every column of the table, in table order, comma-separated.
#                Descriptive only: it is not part of the key, is not
#                ASCII-guaranteed, and a column name containing a comma makes
#                it ambiguous. Never compare it and never parse it.
#   .scope$    - the declared scope as a reader would say it, "" here.
#                Descriptive only, on the same terms as .covers$.
#   .nScope    - how many scope items the key carries: 0 here
#   .nRows     - rows in the table
#   .nCols     - columns in the table
#   .nChars    - characters folded into the digest, content and scope
#   .error$    - "" on success, diagnostic otherwise
#
# THE ONE REFUSAL is a table ID that is not a positive number, which is what
# an uninitialised caller variable looks like. Selecting on it would abort
# the whole script, and a caller that has lost track of its table should get
# a re-run and not a crash. A well-formed ID naming an object that is not a
# Table cannot be detected from script and is not claimed to be.
#
# AN EMPTY .result$ IS NOT A KEY AND MUST NEVER MATCH ONE. When no key can be
# computed the safe answer is "the data is not what it was", so callers
# re-run. @emlFingerprintsAgree enforces that; do not compare with "=".
#
# AN EMPTY TABLE IS NOT AN ERROR. A table of no rows is a data state like any
# other and gets a key, so that a store written when a table was empty does
# not agree with one written after it was filled.
# ============================================================================
procedure emlDataFingerprint: .tableId
    @eml_fpCompose: .tableId, 0, "", ""

    .result$ = eml_fpCompose.result$
    .summary$ = eml_fpCompose.summary$
    .covers$ = eml_fpCompose.covers$
    .scope$ = eml_fpCompose.scope$
    .nScope = eml_fpCompose.nScope
    .nRows = eml_fpCompose.nRows
    .nCols = eml_fpCompose.nCols
    .nChars = eml_fpCompose.nChars
    .error$ = eml_fpCompose.error$
endproc


# ============================================================================
# @emlGroupFingerprint
# ============================================================================
# THE TWO-COLUMN DOOR, for a group comparison: one value column against one
# grouping column.
#
# IT CARRIES BOTH HALVES. The whole table's content is in the key, so an edit
# to a column neither argument names still invalidates it. Both column names
# are in the key, so the same table analysed as ("val", "grp") and as
# ("val2", "grp2") yields two different keys and a store cannot serve one
# comparison's result to a figure drawing the other.
#
# THE NAMES ARE FOLDED VERBATIM AND IN ORDER. ("val", "grp") and
# ("grp", "val") are two scopes. A name that is not a column of the table is
# not resolved and not refused: it folds like any other text, so it yields a
# key of its own that only the same typo matches. See WHY THE SCOPE IS FOLDED
# VERBATIM in the section header.
#
# Arguments:
#   .tableId   - ID of the Table object
#   .dataCol$  - the value column, as the caller names it
#   .groupCol$ - the grouping column, as the caller names it
#
# Output: as @emlDataFingerprint, with .nScope = 2 and .scope$ naming both
#         columns.
# ============================================================================
procedure emlGroupFingerprint: .tableId, .dataCol$, .groupCol$
    @eml_fpCompose: .tableId, 2, .dataCol$, .groupCol$

    .result$ = eml_fpCompose.result$
    .summary$ = eml_fpCompose.summary$
    .covers$ = eml_fpCompose.covers$
    .scope$ = eml_fpCompose.scope$
    .nScope = eml_fpCompose.nScope
    .nRows = eml_fpCompose.nRows
    .nCols = eml_fpCompose.nCols
    .nChars = eml_fpCompose.nChars
    .error$ = eml_fpCompose.error$
endproc


# ============================================================================
# @emlAnalysisFingerprint
# ============================================================================
# THE LIST DOOR, for an analysis whose declaration is one string the caller
# wrote — three columns for a two-way design, a covariate beside a factor, a
# subject column beside a condition.
#
# IT CARRIES BOTH HALVES, on the same terms as @emlGroupFingerprint: the whole
# table's content, and the declaration.
#
# THE LIST IS ONE ITEM AND NOTHING PARSES IT. No separator is split on, no
# empty item is dropped, no role prefix is stripped, no name is resolved.
# "val,grp", "val,,grp", "grp,val" and "num:val,lab:grp" are four strings and
# therefore four scopes. That is what stops two different declarations folding
# to one key.
#
# A LIST IS NOT A PAIR. This door folds one scope item and
# @emlGroupFingerprint folds two, and the item count is in the digest, so
# "val,grp" here never agrees with ("val", "grp") there. A store keyed through
# one door does not serve the other; the cost is a re-run, the alternative is
# a rule about how a list joins that nothing could enforce.
#
# Arguments:
#   .tableId     - ID of the Table object
#   .columnList$ - the declaration, folded verbatim as one item
#
# Output: as @emlDataFingerprint, with .nScope = 1 and .scope$ the list as
#         the caller wrote it.
# ============================================================================
procedure emlAnalysisFingerprint: .tableId, .columnList$
    @eml_fpCompose: .tableId, 1, .columnList$, ""

    .result$ = eml_fpCompose.result$
    .summary$ = eml_fpCompose.summary$
    .covers$ = eml_fpCompose.covers$
    .scope$ = eml_fpCompose.scope$
    .nScope = eml_fpCompose.nScope
    .nRows = eml_fpCompose.nRows
    .nCols = eml_fpCompose.nCols
    .nChars = eml_fpCompose.nChars
    .error$ = eml_fpCompose.error$
endproc


# ============================================================================
# @emlFingerprintsAgree
# ============================================================================
# The one place two fingerprints are compared. TEXT EQUALITY, NEVER NUMERIC
# EQUALITY. Nothing re-parses a fingerprint into a number, so no text round
# trip can perturb it. A tolerance-based numeric comparison would be strictly
# worse: it would have to be loose enough to absorb numerical noise, which is
# the same width as the data edits the key exists to catch.
#
# AN EMPTY FINGERPRINT ON EITHER SIDE MEANS "NOT KNOWN", AND NOT KNOWN NEVER
# AGREES: a result whose key could not be computed, or a store that has never
# been written, must send the caller back to the analysis rather than let a
# figure quote a number that was computed from something else.
#
# THE FORMAT TAG IS PART OF THE TEXT, so two keys written under different
# tags cannot agree even if every other field happens to match. That is
# deliberate and is the whole reason the tag exists.
#
# THE SCOPE IS PART OF THE TEXT TOO, through the digest and through the s=
# field, so two keys taken on the same table for two different analyses do
# not agree. That is this procedure's whole contribution to the scope half of
# the key: it compares the string it is given and asks nothing about how the
# string was built.
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


# ============================================================================
# THE RESULT STORE: THE SINGLE WRITE SITE
# ============================================================================
# Provides: @emlStoreKeyTake, @emlPublishAnalysisResult,
#           @emlStoreIdentityAgrees
#
# WHY IT IS IN THIS FILE, BESIDE THE KEY AND NOT IN A MODULE OF ITS OWN.
# The store is one mechanism with two halves -- the key that says whether a
# result still describes the table, and the publication that states the
# result -- and both halves are needed by both sides: the statistics kernels
# publish, and the graphs layer publishes and will consume. That is the same
# argument that put the fingerprint here, written out at the top of this file,
# and it holds for the publication for the same reason.
#
# THE OTHER HALF OF THE ANSWER IS A COST, AND IT IS NAMED RATHER THAN LEFT
# IMPLIED. A new module under stats/ is a new row in setup.praat's barrel
# table, which is pinned against the include block @emlRecordRender writes
# into every recorded script (validate/v82) -- so it re-baselines every
# committed recording, roundtrip byte-comparison and emitted script in the
# harness tree, 402 committed artefacts at the time of writing. The 25 August
# risk register calls that wave R2: a re-baseline is where an unintended
# change hides inside expected churn, and the standing ruling batches such
# re-drives once, at the end of the round. A filing decision is not worth
# spending that on mid-round. If the store is later given its own module, it
# rides that batched re-drive.

# ============================================================================
# WHAT IS RULED, AND IS NOT OPEN
# ============================================================================
# docs/RULING_RESULT_STORE.md section (d). The store lives in PUBLISHED
# GLOBALS, not in an Objects-window Table. A Table is user-deletable
# mid-session — the recorder already had to grow orphan handling for exactly
# that — it complicates the selection contract, and bookkeeping tables in the
# Objects window have been objected to. That is decided; this section
# implements it rather than reconsidering it.
#
# GLOBALS ARE CHOSEN WITH THE DISCIPLINE THAT ANSWERS THEIR INVISIBILITY, and
# the discipline is the whole of this section:
#
#   ONE WRITE SITE. @emlPublishAnalysisResult is the only procedure in the
#   plugin that assigns a name beginning emlStore. Nothing else writes one,
#   ever, and a check asserts it over the whole tree.
#
#   THE WHOLE RESULT, ON EVERY RUN. Every published name is stated on every
#   publication — the test type, the correction, alpha, the statistics, the
#   matrices and the section (a) data key — the way the pens are stated on
#   every press (@emlGraphsPublishSeriesPens). PRAAT CANNOT UNSET A VARIABLE,
#   so a name left unwritten by this run is not absent: it is the PREVIOUS
#   run's value, wearing this run's key. Stating everything is what makes
#   "published" and "current" the same thing.
#
#   EVERY DOOR THAT COMPUTES PUBLISHES. A door that computes a group
#   comparison and does not publish leaves the door before it standing as the
#   answer. That is the defect this contract exists to prevent, and the
#   population is DERIVED — see WHICH RUNS PUBLISH below — rather than kept
#   as a list somebody remembers to extend.
#
# PUBLISHED STATE UNDER A SINGLE-WRITER CONTRACT WITH A VALIDATOR CENSUS IS
# NOT HIDDEN STATE. That is the ruling's sentence, and the census is
# validate/v138_result_store.R.
#
# ============================================================================
# WHICH RUNS PUBLISH, AND HOW THAT POPULATION IS DERIVED
# ============================================================================
# NOT FROM A LIST. A list of publishing doors is a list that goes stale the
# first time a door is added, and the failure is silent: the new door computes
# and the last door's result is still published.
#
# THE DERIVATION. A run computes a GROUP COMPARISON when it reads one numeric
# column split by the levels of one grouping column and computes an
# inferential statistic from the split. In this tree that is visible in
# source: such a run calls one of the value-by-group kernels —
#
#   @emlOneWayAnova  @emlKruskalWallis  @emlTukeyHSD    @emlDunnTest
#   @emlPairwiseT    @emlPairwiseWilcoxon  @emlScheffe   @emlWelchAnova
#   @emlGamesHowell  @emlBrownForsythe
#
# — each of which takes (.tableId, .dataCol$, .factorCol$), or splits the
# column itself with @eml_getGroupData and hands the two vectors to @emlTTest
# or @emlMannWhitneyU. validate/v138_result_store.R walks the shipped tree for
# those calls, maps each to the procedure it sits in, and asserts that every
# such procedure either publishes or is named in a committed exemption with
# its reason. A new door that computes reddens the check on the day it is
# written, not on the day a figure quotes it.
#
# WHAT THE WALK FINDS TODAY, and why each is what it is:
#
#   @emlRunTwoGroupAnalysis   PUBLISHES  the two-group menu door
#   @emlRunAnovaAnalysis      PUBLISHES  the one-way ANOVA menu door
#   @emlRunKWAnalysis         PUBLISHES  the Kruskal-Wallis menu door
#   @emlRunPairwiseAnalysis   PUBLISHES  the pairwise menu door
#   @emlBridgeGroupComparison PUBLISHES  the GRAPH door — the driven defect
#
#   @emlReportAnovaComparison EXEMPT — it is the report half of a run, not a
#   @emlReportKWComparison    run. Both are called BY the orchestrator above
#                             and BY the bridge, and the extra comparisons
#                             they compute (Brown-Forsythe, Welch's ANOVA,
#                             Games-Howell, per-pair rank-biserial r) belong
#                             to the run that called them. A reporter that
#                             published would publish twice per run and the
#                             second publication would be the one that stood.
#
# ACOUSTICS ARE OUT, BY RULING (section e): there is no analysis-door /
# graph-door result pair to reconcile there, and the fix for that class is
# canonical parameters plus the cross-door agreement leg.
#
# THE SCATTER'S DRAW-TIME CORRELATION is ruled INTO the store (section e) and
# is NOT wired here. This build is the group-comparison population; the
# mechanism is generic over "analysis result" and the correlation door joins
# it by calling this same procedure with .kind$ = "correlation". Nothing in
# this section is specific to a group comparison except the vocabulary of
# .kind$ and the two-name shape of the key, and both are stated below.
#
# ============================================================================
# WHERE THE KEY IS TAKEN, AND WHY IT IS TAKEN THERE
# ============================================================================
# THE FINGERPRINT'S OWN HEADER CARRIES THE INSTRUCTION THIS FILE HONOURS, and
# it is the one failure the arithmetic cannot see:
#
#   "A key describes the table at the instant it is asked for, and a caller
#    that computes a result, lets the table change, and only then stamps a key
#    has stamped a truthful key on a result the table does not support.
#    Nothing inside this module can detect that: the fault is in the ORDER of
#    the calls, not in the arithmetic. THE RULE THAT CLOSES IT IS THE
#    CALLER'S: take the key in the same pass that reads the data, before
#    anything can touch the table."
#
# SO THE KEY IS TAKEN BY @emlStoreKeyTake, AT THE TOP OF THE RUN'S READING
# PASS — after the column guards, before the first kernel call and before the
# first @eml_getGroupData. Every publisher takes it there and carries it in a
# local to the publication at the end. Between the take and the reads there is
# no dialog, no draw, no user, and no other script: a Praat script is one
# thread and a run is one uninterrupted stretch of it.
#
# WHY NOT TAKE IT IN THE WRITE SITE. Because the write site runs at the END of
# the run, after the reporter, and a key taken there is truthful about the
# wrong moment. It would be the easy shape — one call, nothing for a caller to
# get wrong — and it would reintroduce exactly the failure the fingerprint's
# header names. The cost of the shape chosen instead is that a caller CAN get
# it wrong, so it is checked: v138 asserts, for every publishing procedure,
# that the @emlStoreKeyTake call comes before the first value-by-group read.
#
# THE READING STAMP CARRIES THE SORT ORDER TOO, for the same reason it carries
# the key. emlGroupSortAlphabetical decides the order the levels are
# discovered in, and therefore the ORDER EVERY PAIRWISE CONTRAST IS FORMED IN:
# the same two levels read "Zebra - Alpha = +10.0000" under one setting and
# "Alpha - Zebra = -10.0000" under the other, sign and names together. It is
# part of what the reading pass produced, so it is stamped where the reading
# pass began and not read again at publication time.
#
# ============================================================================
# WHAT MAKES A STORED RESULT'S IDENTITY (punch list item 1.4)
# ============================================================================
# THE COLUMN NAMES, THE TEST TYPE, THE CORRECTION METHOD, ALPHA, AND THE GROUP
# SORT ORDER. A mismatch on any of the five is a DIFFERENT ANALYSIS, not
# changed data, and the distinction is not cosmetic: the two are handled
# differently on purpose.
#
#   IDENTITY IS COMPARED AS IDENTITY, field by field, by
#   @emlStoreIdentityAgrees below. A caller learns WHICH field differs and
#   what it was, which is what the ruling's one-line announcement needs.
#
#   THE REPORT IS COMPARED AS TEXT (item 1.2). Different questions, different
#   comparisons: "is this the same analysis?" and "has what the user reads
#   changed?" are not the same question and must not share an answer.
#
# THE GROUP SORT ORDER HAS NO DIALOG CONTROL OF ITS OWN. It is a global the
# graphs form sets from config_groupSort; the settings census found it by
# walking the code, and a census that enumerated dialog controls never would
# have. It is result-affecting all the same, and it is in the identity for
# that reason and no other.
#
# ============================================================================
# VALIDITY IS THE FINGERPRINT, NOT A CONSUMED-ONCE STAMP
# ============================================================================
# Unlike the axis request (ruling A, consumed once by design), a result is
# legitimately consumed by MANY figures until the data or a result-affecting
# setting changes. So there is no step stamp here and no consumption to
# record. emlStoreRun counts publications and is a DIAGNOSTIC — it says which
# publication a reader is looking at, and it must never be read as validity.
# Validity is: the schema tag matches, emlStoreValid is 1, the key agrees
# under @emlFingerprintsAgree, and the identity agrees under
# @emlStoreIdentityAgrees. Four questions, none of them a counter.
#
# ============================================================================
# WHAT IS PUBLISHED
# ============================================================================
# Every name below is stated on every publication. The census in
# validate/v138_result_store.R reads this list off the write site's body and
# holds it to a committed classification, both ways: a published name that is
# not classified is red, and a classification whose name is not published is
# red.
#
# FORMAT AND LIFECYCLE
#   emlStoreFormat$        format tag, "eRS1". Change the composition,
#                           change the tag; a reader compares it before it
#                           reads anything else, so a store written under an
#                           older shape cannot be misread as this one.
#   emlStoreRun            publication counter. DIAGNOSTIC, never validity.
#   emlStoreValid          1 when this run computed a result, 0 when it
#                           refused. A refusal publishes: it is what stops
#                           the previous run's result standing as this one's.
#   emlStoreError$         the producer's own refusal text, "" when valid.
#                           Never composed here.
#   emlStoreProducer$      the procedure that published — diagnostic, and
#                           what makes "which door answered?" answerable.
#   emlStoreDoor$          "menu" or "figure". Descriptive: a result computed
#                           at either door with the same identity IS the same
#                           analysis, so this is not part of the identity.
#   emlStoreKind$          the analysis family: "group" today; "correlation"
#                           and "regression" when section (e)'s second door
#                           joins. A reader that does not recognise the kind
#                           re-runs rather than guessing.
#
# THE DATA KEY (ruling section a)
#   emlStoreKeyError$      why no key could be taken, in the fingerprint's own
#                          words, or "" when one was. A KEY THAT COULD NOT BE
#                          TAKEN IS ALREADY SAFE -- "" never agrees, so the
#                          analysis re-runs -- but a store that dropped the
#                          reason on the floor would be a new member of the
#                          silent class the error census counted 19 of (punch
#                          list lane 9). It costs one name to say why.
#   emlStoreKey$           the section (a) fingerprint, taken by
#                           @emlStoreKeyTake in the run's reading pass. ""
#                           when no key could be taken, which never agrees.
#   emlStoreTableId        the Table the run read
#   emlStoreTableName$     its object name, for the Info window
#
# THE IDENTITY (punch list 1.4) — compared as identity, never as text
#   emlStoreDataCol$       the value column
#   emlStoreGroupCol$      the grouping column
#   emlStoreTestType$      canonical key for the test that ran (see
#                           THE KEYS ARE KEYS below)
#   emlStoreCorrection$    the multiple-comparison adjustment: "holm",
#                           "bonferroni", "bh", or "" where none applies
#   emlStoreAlpha          the threshold the verdicts were taken at
#   emlStoreGroupSort$     "table" or "alphabetical", stamped at the read
#
# THE GROUPS
#   emlStoreNGroups        k
#   emlStoreGroupLabel$[i] level i, in the order the analysis formed its
#                           contrasts — which is what emlStoreGroupSort$
#                           describes. Slots above k are blanked on every
#                           publication; see THE STALE SLOT below.
#
# THE STATISTICS
#   emlStoreOmnibusLabel$  "F", "H", "t", "U", or "" where the family has no
#                           single statistic (the pairwise door)
#   emlStoreOmnibusStat    its value, undefined where there is none
#   emlStoreDf1            first df, undefined where there is none
#   emlStoreDf2            second df, undefined where there is none
#   emlStoreOmnibusP       the omnibus p, undefined where there is none
#   emlStoreEffectLabel$   "eta squared", "epsilon squared", "Cohen's d",
#                           "rank-biserial r", or ""
#   emlStoreEffect         its value, undefined where there is none
#   emlStoreN              the analysed N where the producer states one,
#                           undefined where it does not. UNDEFINED MEANS THE
#                           PRODUCER DID NOT STATE IT and never means zero.
#
# THE SECOND ARM, WHERE A DOOR RUNS TWO TESTS OF ONE HYPOTHESIS
#   emlStoreSecondLabel$   "U" beside the primary "t", or "" when only one
#                           test ran
#   emlStoreSecondStat     its value, undefined where there is none
#   emlStoreSecondDf1      its df, undefined where the test has none
#   emlStoreSecondP        its p, undefined where there is none
#   emlStoreSecondEffectLabel$ / emlStoreSecondEffect
#
# THESE SIX EXIST BECAUSE "BOTH" IS A REAL CHOICE AND ONE PAIR OF SLOTS
# CANNOT HOLD IT. The two-group door offers Welch t beside Mann-Whitney U,
# and a run that computed two tests and published one would be the
# field-level version of the very defect the single-writer contract is
# for -- computed and not published. THE PRIMARY SLOTS HOLD THE PARAMETRIC
# ARM WHERE ONE RAN, the nonparametric arm otherwise, and the second slots
# hold the other arm or state that there was none. Which tests ran is not
# inferred from these slots by anyone: emlStoreTestType$ says it, and says
# it as identity, so "welch t", "mann-whitney" and "welch t + mann-whitney"
# are three different analyses and compare as three.
#
# THE POST-HOC AND ITS MATRICES
#   emlStorePostHoc$       "tukey", "dunn", "welch t", "student t",
#                           "wilcoxon", "scheffe", or "" when none ran
#   emlStoreHasMatrix      1 when the four matrices below describe k x k
#                           pairs, 0 when no post-hoc ran
#   emlStorePMatrix##      adjusted p per pair, symmetric, diagonal 1
#   emlStoreDiffMatrix##   signed difference i minus j, antisymmetric
#   emlStoreStatMatrix##   the per-pair test statistic, named by
#   emlStoreStatLabel$     "q", "z", "t", "U", "F", or ""
#   emlStoreEffectMatrix## the signed per-pair effect size, named by
#   emlStorePairEffectLabel$  "Cohen's d", "rank-biserial r", or ""
#
# MATRIX GLOBALS CARRY THE PAIRWISE MATRICES WITHOUT TROUBLE — that is the
# ruling's sentence and it is measured: a k x k matrix assigned to a global
# from inside a procedure reads back whole, by value.
#
# THE STORE PUBLISHES THE SIGNED NUMERIC RESULT AND LETS EACH LAYOUT TAKE WHAT
# IT NEEDS. There is deliberately no significance matrix: a verdict is
# p < alpha, both of which are published, and the bracket arm and the matrix
# arm of the drawing layer already disagree about whether to show the sign
# (the matrix arm prints abs(d) and a formatted p). A store that published a
# verdict would be publishing one layout's rendering as if it were the result.
#
# THE KEYS ARE KEYS, NOT TEXT FOR A READER. emlStoreTestType$,
# emlStoreCorrection$, emlStorePostHoc$, emlStoreKind$ and
# emlStoreGroupSort$ are canonical lowercase keys, on the same terms as the
# "holm" / "bonferroni" / "bh" the adjustment travels under everywhere else in
# this plugin. NOTHING PRINTS THEM. A door that wants display text maps the
# key the way @emlAdjustMethodDisplay does, and no approved wording is
# invented here.
#
# WHAT IS NOT PUBLISHED YET, NAMED RATHER THAN LEFT TO BE DISCOVERED:
#
#   THE REPORT TEXT. Punch list item 1.2 keeps the report beside the key, in
#   CANONICAL form — rendered with explanation-routed lines suppressed, so the
#   comparison sees numbers and disclosures only. The canonical renderer does
#   not exist yet and the reporters print straight to the Info window rather
#   than returning their text, so there is nothing truthful to publish today.
#   It joins by gaining one argument HERE, at the one write site, which is
#   what having one write site is for. A slot published empty in the meantime
#   would be a name a reader could compare and always find equal.
#
#   THE PER-GROUP DESCRIPTIVES. n, mean, SD and median per level are computed
#   by the REPORTERS, not by the kernels, and are printed rather than
#   returned. The ruling's publication list does not name them; the reprint
#   rule compares them as report text. They join the same way the report does.
#
# ============================================================================
# THE STALE SLOT, AND WHY THE LABELS ARE BLANKED
# ============================================================================
# MEASURED, ON PRAAT 6.6.30, and it is the whole reason the write site blanks
# anything: publish two levels, then publish one, and emlStoreGroupLabel$[2]
# still reads "Zebra". Praat cannot unset a variable and an indexed slot is no
# exception, so a three-group result followed by a two-group result would
# leave a third label standing beside a k of 2 — a label a reader could pair
# with a matrix row that is not there. Every publication therefore blanks the
# slots from k + 1 up to the k of the publication before it.
#
# THE SAME HAZARD IS WHY THERE IS NO "CLEAR THE STORE" PROCEDURE. Clearing is
# a second write site by another name, and a store cleared by one path and
# published by another has two truths. A run that refuses publishes its
# refusal instead, which states every name — including a key of "", which
# @emlFingerprintsAgree refuses to match — and leaves nothing of the previous
# run behind.
#
# ============================================================================
# HOW THE ARGUMENTS ARE SHAPED, AND THE ONE THING PRAAT CANNOT PASS
# ============================================================================
# @emlPublishAnalysisResult takes the whole result as arguments, in one call,
# because that is what makes "stated in full on every run" a thing the
# interpreter enforces: Praat refuses a call whose argument count does not
# match the signature, so a publisher that forgets a field does not compile.
#
# THE LEVEL LABELS ARE THE EXCEPTION, AND ONLY BECAUSE PRAAT HAS NO ARRAY
# PARAMETER. They arrive through emlPublishInLabel$[1..k], which is an
# ARGUMENT in the only shape the language offers for one — the caller fills
# it immediately before the call, the write site copies it, and nothing reads
# it as the store. IT IS NAMED emlPublishIn... AND NOT emlStore..., so that
# the single-writer rule can be stated without an exception in it: NOTHING BUT
# @emlPublishAnalysisResult ASSIGNS A NAME BEGINNING emlStore, anywhere in
# the tree, and validate/v138_result_store.R reads that sentence literally.
#
# A QUANTITY THE RUN DID NOT COMPUTE IS HANDED OVER AS A MATRIX OF UNDEFINED,
# from @emlPublishAbsentMatrix below, and never as zeros. That is the tree's
# own convention -- punch list item 9.1 replaced exactly such a zero-fill,
# because a failed pair printing as "0.000" reads as a true zero effect -- and
# it is why a one-way ANOVA run without Tukey publishes a k x k p matrix of
# undefined beside its real effect-size matrix, rather than a 1 x 1 nothing
# that a reader would have to know to interpret.
#
# ============================================================================
# POST-1.0
# ============================================================================
# EMMs, diagnostics and the LMM phases consume this store natively. NOBODY
# BUILDS A SECOND ONE. If a paired or repeated door joins, row pairing enters
# the KEY at that moment — the whole-table fingerprint already carries it,
# because every cell is folded in the order the table holds it — and the
# two-name key take here grows a list-shaped sibling that uses
# @emlAnalysisFingerprint. Two-way stays keyless by ruling (punch list 1.3).
# ============================================================================


# ============================================================================
# @emlStoreKeyTake
# ============================================================================
# THE RUN'S READING STAMP: the section (a) data key and the group sort order
# in force, taken together, at the top of the pass that reads the data.
#
# CALL IT AFTER THE COLUMN GUARDS AND BEFORE THE FIRST VALUE-BY-GROUP READ.
# After the guards, because a run that refuses on a guard has no result to key
# and publishes a refusal with no key. Before the first read, because that is
# the instant the key has to describe: see WHERE THE KEY IS TAKEN in the
# section header, which quotes the fingerprint's own instruction.
#
# COPY THE OUTPUTS ON THE NEXT LINE. A procedure's outputs survive only until
# it runs again, and this one is called once per publishing run — but the
# publication is at the far end of the run, past the kernels and the reporter,
# and the house rule exists for exactly that distance.
#
# WHICH FINGERPRINT DOOR, DECIDED HERE AND NOT AT THE CALL SITES. A group
# comparison keys through @emlGroupFingerprint, the two-name door, always. The
# doors do not fold to one another — a two-name scope never equals a one-item
# list scope on the same table, deliberately — so a publisher that reached for
# @emlAnalysisFingerprint would key its result out of reach of every other
# publisher of the same comparison, and the store would miss every time
# without ever being wrong out loud. One decision, one place.
#
# Arguments:
#   .tableId   - the Table the run is about to read
#   .dataCol$  - the value column, as the run names it
#   .groupCol$ - the grouping column, as the run names it
#
# Output:
#   .key$    - the fingerprint, or "" if none could be taken
#   .sort$   - "table" or "alphabetical": the order the levels will be
#              discovered in, and therefore the order the contrasts will be
#              formed in
#   .error$  - "" on success, the fingerprint's own diagnostic otherwise
# ============================================================================
procedure emlStoreKeyTake: .tableId, .dataCol$, .groupCol$
    @emlGroupFingerprint: .tableId, .dataCol$, .groupCol$
    ; THE ERROR IS READ BEFORE THE OUTPUT IT GUARDS, which is lane 9.2's rule
    ; and the order validate/v134's lint reads. Not a formality: the
    ; fingerprint's one refusal returns an EMPTY key, and a caller that took
    ; the key first and the diagnosis afterwards is one edit away from never
    ; taking the diagnosis at all.
    .error$ = emlGroupFingerprint.error$
    .key$ = emlGroupFingerprint.result$

    ; READ THROUGH THE GUARD. eml-extract.praat declares this global at load
    ; and every barrel loads that file first, so it is there for every shipped
    ; path -- but a probe or a test that includes only part of the stats tree
    ; reaches this procedure without it, and an unguarded read aborts the
    ; script rather than keying the run. Absent means table order, which is
    ; the declared default and the order this plugin used before the control
    ; existed.
    .sort$ = "table"
    if variableExists ("emlGroupSortAlphabetical")
        if emlGroupSortAlphabetical = 1
            .sort$ = "alphabetical"
        endif
    endif
endproc


# ============================================================================
# @emlPublishAbsentMatrix
# ============================================================================
# The shape a publisher hands the write site for a k x k quantity THIS RUN DID
# NOT COMPUTE: every cell undefined.
#
# NOT ZEROS, AND THE TREE HAS ALREADY PAID FOR THIS LESSON ONCE. Punch list
# item 9.1 took the zero-fill out of the effect-size matrices because a pair
# whose computation failed printed as "0.000" and read as a true zero effect —
# a number a reader believes. undefined is what @eml_fixed refuses to round
# silently and what the printers already show as "n/a", so an absent quantity
# stays absent all the way to the page.
#
# NOT A 1 x 1 EITHER. The matrices are published at the shape of the group
# set, so a reader indexing by group index gets undefined for a quantity that
# was not computed rather than an out-of-range abort or, worse, a cell from
# some other run's matrix.
#
# Arguments:
#   .k   - the number of groups
#
# Output:
#   .m## - a k x k matrix, every cell undefined. Read it on the next line:
#          this procedure runs again for the next absent quantity.
# ============================================================================
procedure emlPublishAbsentMatrix: .k
    .m## = zero## (.k, .k)
    for .i from 1 to .k
        for .j from 1 to .k
            .m## [.i, .j] = undefined
        endfor
    endfor
endproc

# ============================================================================
# @emlPublishAnalysisResult — THE WRITE SITE
# ============================================================================
# THE ONE PLACE ANY emlStore NAME IS ASSIGNED. Every publisher calls this and
# nothing else writes the store, so there is one thing to read and one thing
# to change. validate/v138_result_store.R asserts the whole tree against that
# sentence.
#
# IT COMPUTES NOTHING AND PRINTS NOTHING. Every number it publishes was
# computed by the run that is handing it over; it does not re-read the table,
# does not re-derive a verdict from p and alpha, and appends no line to the
# Info window. A write site that computed would be a second analysis with no
# door of its own, and one that printed would put a report where the ruling
# says a report must not be.
#
# THERE IS NO BRANCH IN IT AROUND A PUBLICATION. Every published name is
# assigned unconditionally, once, on the only path through this body. That is
# what lets a reader guard on ONE name — emlStoreFormat$ — and know the rest
# are there: they are written in one pass with no goto and no early exit. The
# two loops at the end write the level labels and blank the slots above them,
# and a loop with an empty range writes nothing, which is the same statement.
#
# Arguments, in the order the section header lists them:
#   .producer$    the procedure publishing, for diagnosis
#   .door$        "menu" or "figure"
#   .kind$        the analysis family: "group"
#   .error$       the producer's refusal text, "" when the run computed
#   .key$         the key from @emlStoreKeyTake, taken at the read
#   .keyError$    that call's own error text, "" when a key was taken
#   .tableId      the Table the run read
#   .tableName$   its object name
#   .dataCol$     identity: the value column
#   .groupCol$    identity: the grouping column
#   .testType$    identity: canonical key for the test that ran
#   .correction$  identity: the adjustment key, "" where none applies
#   .alpha        identity: the threshold the verdicts were taken at
#   .sort$        identity: the sort order from @emlStoreKeyTake
#   .nGroups      k, with the labels in emlPublishInLabel$[1..k]
#   .omnibusLabel$ / .omnibusStat / .df1 / .df2 / .omnibusP
#   .effectLabel$ / .effect
#   .n            the analysed N, undefined where the producer states none
#   .secondLabel$ / .secondStat / .secondDf1 / .secondP
#   .secondEffectLabel$ / .secondEffect
#                 the second arm where a door ran two tests of one
#                 hypothesis; "" and undefined where it ran one
#   .postHoc$     which post-hoc produced the matrices, "" when none did
#   .hasMatrix    1 when the matrices describe k x k pairs, 0 otherwise
#   .statLabel$   what .statMatrix## holds: "q", "z", "t", "U", "F" or ""
#   .pairEffectLabel$  what .effectMatrix## holds, or ""
#   .pMatrix## / .diffMatrix## / .statMatrix## / .effectMatrix##
#
# Output: the published globals listed in WHAT IS PUBLISHED. No dotted output;
#         a caller that wants to know what it just published reads the store.
# ============================================================================
procedure emlPublishAnalysisResult: .producer$, .door$, .kind$, .error$,
    ... .key$, .keyError$, .tableId, .tableName$,
    ... .dataCol$, .groupCol$, .testType$, .correction$, .alpha, .sort$,
    ... .nGroups, .omnibusLabel$, .omnibusStat, .df1, .df2, .omnibusP,
    ... .effectLabel$, .effect, .n,
    ... .secondLabel$, .secondStat, .secondDf1, .secondP,
    ... .secondEffectLabel$, .secondEffect,
    ... .postHoc$, .hasMatrix, .statLabel$, .pairEffectLabel$,
    ... .pMatrix##, .diffMatrix##, .statMatrix##, .effectMatrix##

    ; HOW MANY LABEL SLOTS THE PUBLICATION BEFORE THIS ONE LEFT BEHIND. Read
    ; before anything is written, guarded because the first publication of a
    ; session has no predecessor. This is a local read, not a publication:
    ; no published name is written inside a branch anywhere in this body.
    .prevGroups = 0
    if variableExists ("emlStoreNGroups")
        .prevGroups = emlStoreNGroups
    endif
    .prevRun = 0
    if variableExists ("emlStoreRun")
        .prevRun = emlStoreRun
    endif
    ; VALID IS DECIDED FROM THE PRODUCER'S OWN ERROR TEXT and from nothing
    ; else. This procedure does not judge a result; it repeats what the run
    ; that computed it said about itself.
    .valid = 1
    if .error$ <> ""
        .valid = 0
    endif

    ; -- format and lifecycle --------------------------------------------
    emlStoreFormat$ = "eRS1"
    emlStoreRun = .prevRun + 1
    emlStoreValid = .valid
    emlStoreError$ = .error$
    emlStoreProducer$ = .producer$
    emlStoreDoor$ = .door$
    emlStoreKind$ = .kind$

    ; -- the data key ----------------------------------------------------
    emlStoreKey$ = .key$
    emlStoreKeyError$ = .keyError$
    emlStoreTableId = .tableId
    emlStoreTableName$ = .tableName$

    ; -- the identity (punch list 1.4) -----------------------------------
    emlStoreDataCol$ = .dataCol$
    emlStoreGroupCol$ = .groupCol$
    emlStoreTestType$ = .testType$
    emlStoreCorrection$ = .correction$
    emlStoreAlpha = .alpha
    emlStoreGroupSort$ = .sort$

    ; -- the groups ------------------------------------------------------
    emlStoreNGroups = .nGroups

    ; -- the statistics --------------------------------------------------
    emlStoreOmnibusLabel$ = .omnibusLabel$
    emlStoreOmnibusStat = .omnibusStat
    emlStoreDf1 = .df1
    emlStoreDf2 = .df2
    emlStoreOmnibusP = .omnibusP
    emlStoreEffectLabel$ = .effectLabel$
    emlStoreEffect = .effect
    emlStoreN = .n

    ; -- the second arm, where a door ran two tests of one hypothesis ------
    emlStoreSecondLabel$ = .secondLabel$
    emlStoreSecondStat = .secondStat
    emlStoreSecondDf1 = .secondDf1
    emlStoreSecondP = .secondP
    emlStoreSecondEffectLabel$ = .secondEffectLabel$
    emlStoreSecondEffect = .secondEffect

    ; -- the post-hoc and its matrices -----------------------------------
    emlStorePostHoc$ = .postHoc$
    emlStoreHasMatrix = .hasMatrix
    emlStoreStatLabel$ = .statLabel$
    emlStorePairEffectLabel$ = .pairEffectLabel$
    emlStorePMatrix## = .pMatrix##
    emlStoreDiffMatrix## = .diffMatrix##
    emlStoreStatMatrix## = .statMatrix##
    emlStoreEffectMatrix## = .effectMatrix##

    ; THE LEVEL LABELS, and then the slots the last publication left above
    ; them. See THE STALE SLOT in the section header: a two-group result
    ; following a three-group one would otherwise leave a third label
    ; standing beside a k of 2.
    for .i from 1 to .nGroups
        emlStoreGroupLabel$ [.i] = emlPublishInLabel$ [.i]
    endfor
    for .i from .nGroups + 1 to .prevGroups
        emlStoreGroupLabel$ [.i] = ""
    endfor
endproc


# ============================================================================
# @emlStoreIdentityAgrees
# ============================================================================
# THE IDENTITY COMPARISON (punch list item 1.4). Asks whether a candidate
# analysis is THE SAME ANALYSIS as the one in the store: same columns, same
# test type, same correction, same alpha, same group sort order.
#
# THIS IS NOT THE DATA QUESTION AND DOES NOT ANSWER IT. @emlFingerprintsAgree
# answers "same data, same declared scope?" and this answers "same analysis?".
# A reader needs both to serve a stored result, and neither substitutes: the
# key holds while the correction changes, and the identity holds while a cell
# is edited.
#
# IT NAMES THE FIRST FIELD THAT DIFFERS, AS A FIELD KEY, because the caller
# that needs to know is the one composing the ruled announcement line
# ("Recomputed: adjustment method holm -> bonferroni", RULING_RESULT_STORE
# section c). THE SENTENCE IS NOT COMPOSED HERE. This returns the key, the old
# value and the new one; whoever prints owns the wording.
#
# FIELD ORDER IS THE ORDER 1.4 LISTS THEM, so two callers that report "the
# first difference" report the same one.
#
# ALPHA IS COMPARED AS A NUMBER, WITH NO TOLERANCE. It reaches both sides from
# the same dialog field or the same default, so equal values are bit-equal;
# a tolerance would have to be wide enough to absorb the difference between
# .05 and .049, which is a different analysis.
#
# AN UNPUBLISHED STORE NEVER AGREES. If nothing has published in this session
# there is no identity to match, and the honest answer is "not the same",
# which sends the caller to re-run. That is the same rule
# @emlFingerprintsAgree applies to an empty key, for the same reason.
#
# Arguments: the candidate's five identity fields plus the group sort order,
#   .dataCol$, .groupCol$, .testType$, .correction$, .alpha, .sort$
#
# Output:
#   .same    - 1 if every field matches the published identity, else 0
#   .field$  - the first differing field's key: "dataColumn", "groupColumn",
#              "testType", "correction", "alpha", "groupSort", or "store"
#              when nothing has published. "" when .same is 1.
#   .was$    - the stored value of that field, as text
#   .now$    - the candidate's value of that field, as text
# ============================================================================
procedure emlStoreIdentityAgrees: .dataCol$, .groupCol$, .testType$,
    ... .correction$, .alpha, .sort$
    .same = 0
    .field$ = "store"
    .was$ = ""
    .now$ = ""

    if variableExists ("emlStoreFormat$")
        if emlStoreFormat$ = "eRS1"
            .same = 1
            .field$ = ""

            if .same = 1 and emlStoreDataCol$ <> .dataCol$
                .same = 0
                .field$ = "dataColumn"
                .was$ = emlStoreDataCol$
                .now$ = .dataCol$
            endif
            if .same = 1 and emlStoreGroupCol$ <> .groupCol$
                .same = 0
                .field$ = "groupColumn"
                .was$ = emlStoreGroupCol$
                .now$ = .groupCol$
            endif
            if .same = 1 and emlStoreTestType$ <> .testType$
                .same = 0
                .field$ = "testType"
                .was$ = emlStoreTestType$
                .now$ = .testType$
            endif
            if .same = 1 and emlStoreCorrection$ <> .correction$
                .same = 0
                .field$ = "correction"
                .was$ = emlStoreCorrection$
                .now$ = .correction$
            endif
            if .same = 1 and emlStoreAlpha <> .alpha
                .same = 0
                .field$ = "alpha"
                .was$ = string$ (emlStoreAlpha)
                .now$ = string$ (.alpha)
            endif
            if .same = 1 and emlStoreGroupSort$ <> .sort$
                .same = 0
                .field$ = "groupSort"
                .was$ = emlStoreGroupSort$
                .now$ = .sort$
            endif
        endif
    endif
endproc
