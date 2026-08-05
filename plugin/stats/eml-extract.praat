# ============================================================================
# EML Stats : Data Extraction Layer
# ============================================================================
# Module: eml-extract.praat
# Version: 1.5
# Date: 2 August 2026
#
# v1.5: Numeric-column integrity and group-label normalisation.
#        (1) @eml_getGroupData / @eml_getGroupPairedData now verify that
#        "Get all numbers in column:" will return VALUES and not Praat's
#        alphabetical RANK substitution, and abort with a clear message
#        when it would not. (2) @emlValidateNumericColumn hardened:
#        per-cell check across every row, strict-numeric verdict, first
#        offending row and its literal contents, and a coercion-hazard
#        warning. It is now actually called (previously zero call sites).
#        (3) number() coercion hazards are detected and reported; the
#        European decimal comma is listed first because it is the only
#        one that yields a plausible wrong number rather than a dropped
#        row. (4) @emlCountGroups normalises group labels (case and
#        leading/trailing whitespace) and warns when normalisation
#        merged distinct spellings; the same normalisation is applied
#        by the group extractors so counting and extraction agree.
#        New helpers: @eml_normalizeLabel, @eml_strictNumericColumn.
#
# v1.4: @eml_getGroupPairedData — row-wise complete-case extraction of
#        two numeric columns within one group, for grouped correlation
#        (keeps X and Y aligned; per-column extraction misaligned pairs
#        on missing data).
# v1.3: @emlGuessColumnRoles — infers column roles (group, data,
#        subject, time, factor) from column names via weighted keyword
#        matching + type detection. Replaces positional guessing in
#        wizard and graph form dialogs. Helper: @eml_kwScan.
# v1.2: Group sort order — @emlCountGroups optionally sorts labels
#        alphabetically when emlGroupSortAlphabetical = 1. Default 0
#        (table/discovery order). Global initialized in this file.
#
# Part of the EML Stats library (EML Praat Tools).
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# v1.1: Deleted @emlExtractMultipleGroups (10-group limit, vector
#        index overflow bug). Replaced with on-demand extraction:
#        @emlCountGroups rewritten (no group limit, no .groupSize
#        outputs), @eml_getGroupData added (4-arg, self-contained,
#        filters undefined values, auto-sized vector via C-level
#        Table extraction). Moved @eml_getGroupData here from
#        eml-inferential.praat (extraction, not inference).
#
# Provides: @emlExtractColumn, @emlExtractColumnAsStrings,
#   @emlExtractGroupVectors, @eml_getGroupData,
#   @emlExtractPairedColumns, @emlExtractPitchValues,
#   @emlExtractFormantValues, @emlExtractIntensityFrames,
#   @emlExtractHarmonicityFrames, @emlValidateTable,
#   @emlValidateNumericColumn, @emlTableColumnNames,
#   @emlCountGroups, @emlGuessColumnRoles,
#   @eml_normalizeLabel, @eml_strictNumericColumn
#
# These procedures extract data from Praat objects into numeric
# vectors suitable for passing to EML Stats statistical procedures.
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
        # Allocate vector
        .data# = zero#(.nRows)
        .n = 0
        .nUndefined = 0
        
        # Extract values
        for .row from 1 to .nRows
            selectObject: .tableId
            .val = Get value: .row, .columnName$
            if .val <> undefined
                .n = .n + 1
                .data#[.n] = .val
            else
                .nUndefined = .nUndefined + 1
            endif
        endfor
        
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
        
        for .row from 1 to .nRows
            selectObject: .tableId
            .grp$ = Get value: .row, .groupCol$
            .val = Get value: .row, .measureCol$
            
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
            .val = Get value: .row, .measureCol$
            
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
        
        for .row from 1 to .nRows
            selectObject: .tableId
            .val1 = Get value: .row, .col1$
            selectObject: .tableId
            .val2 = Get value: .row, .col2$
            
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
                selectObject: .tableId
                .val1 = Get value: .row, .col1$
                selectObject: .tableId
                .val2 = Get value: .row, .col2$
                
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

    .result$ = lowerCase$ (.result$)
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
        for .row from 1 to .nRows
            selectObject: .tableId
            .cell$ = Get value: .row, .columnName$
            if .cell$ = "" or .cell$ = "--undefined--"
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
# Exists for D93. A wrapper's optionmenu is seeded with an INDEX, but the
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
#   .error$            - error message if column not found
#
# Groups are matched on the NORMALISED label (trimmed, case-folded), so
# "Male", "male" and " Male" are one group, not three. The same
# normalisation is applied by @eml_getGroupData and
# @eml_getGroupPairedData, so counting and extraction cannot disagree.
# ============================================================================
procedure emlCountGroups: .tableId, .groupCol$
    .nGroups = 0
    .error$ = ""
    .nMerged = 0
    .mergeWarning$ = ""

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
    .error$ = ""
    @eml_groupSubset: .tableId, .groupCol$, .groupLabel$
    .tempGroup = eml_groupSubset.subsetId
    selectObject: .tempGroup
    .tempClean = Extract rows where: ~self [.dataCol$] <> undefined
    removeObject: .tempGroup
    selectObject: .tempClean
    .n = Get number of rows
    if .n > 0
        @eml_strictNumericColumn: .tempClean, .dataCol$
        .isStrict = eml_strictNumericColumn.strict
        if .isStrict = 1
            selectObject: .tempClean
            .data# = Get all numbers in column: .dataCol$
        else
            @emlValidateNumericColumn: .tempClean, .dataCol$
            .error$ = "Column '" + .dataCol$ + "' in group '"
            .error$ = .error$ + .groupLabel$ + "': "
            .error$ = .error$ + emlValidateNumericColumn.message$
            .n = 0
            .data# = zero# (0)
            removeObject: .tempClean
            exitScript: .error$
        endif
    else
        .data# = zero# (0)
    endif
    removeObject: .tempClean
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
    .error$ = ""
    @eml_groupSubset: .tableId, .groupCol$, .groupLabel$
    .tempGroup = eml_groupSubset.subsetId
    selectObject: .tempGroup
    .beforeN = Get number of rows
    .tempClean = Extract rows where: ~self [.colX$] <> undefined and self [.colY$] <> undefined
    removeObject: .tempGroup
    selectObject: .tempClean
    .n = Get number of rows
    if .n > 0
        @eml_strictNumericColumn: .tempClean, .colX$
        .strictX = eml_strictNumericColumn.strict
        @eml_strictNumericColumn: .tempClean, .colY$
        .strictY = eml_strictNumericColumn.strict
        if .strictX = 1 and .strictY = 1
            selectObject: .tempClean
            .dataX# = Get all numbers in column: .colX$
            .dataY# = Get all numbers in column: .colY$
        else
            .badCol$ = .colY$
            if .strictX = 0
                .badCol$ = .colX$
            endif
            @emlValidateNumericColumn: .tempClean, .badCol$
            .error$ = "Column '" + .badCol$ + "' in group '"
            .error$ = .error$ + .groupLabel$ + "': "
            .error$ = .error$ + emlValidateNumericColumn.message$
            .n = 0
            .dataX# = zero# (0)
            .dataY# = zero# (0)
            .nExcluded = 0
            removeObject: .tempClean
            exitScript: .error$
        endif
    else
        .dataX# = zero# (0)
        .dataY# = zero# (0)
    endif
    .nExcluded = .beforeN - .n
    removeObject: .tempClean
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
    # remove both from consideration. Repeat for all 4 roles.
    # This prevents low-priority roles from stealing high-confidence
    # matches. E.g., "participant" scores group=6 (via "part") but
    # subject=10 — the subject match wins globally.

    for .col from 1 to .nCols
        .taken[.col] = 0
    endfor
    .roleDone[1] = 0
    .roleDone[2] = 0
    .roleDone[3] = 0
    .roleDone[4] = 0

    for .assignRound from 1 to 4
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
                if .roleDone[4] = 0 and .tS[.col] > .bestScore
                    .bestScore = .tS[.col]
                    .bestCol = .col
                    .bestRole = 4
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
            elsif .bestRole = 4
                .timeIdx = .bestCol
            endif
        endif
    endfor

    # ── Secondary data column (paired/correlation) ───────────────────
    # Best unassigned column with a data score, for dialogs needing
    # two numeric columns (paired t-test, correlation).

    .bestD2 = 0
    for .col from 1 to .nCols
        if .taken[.col] = 0 and .dS[.col] > .bestD2
            .bestD2 = .dS[.col]
            .dataIdx2 = .col
        endif
    endfor

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
        if .nCols >= 2
            .dataIdx = 2
        endif
    elsif .groupIdx = 0
        # Data found but no group — first column != dataIdx
        for .col from 1 to .nCols
            if .col <> .dataIdx and .groupIdx = 0
                .groupIdx = .col
            endif
        endfor
    elsif .dataIdx = 0
        # Group found but no data — first column != groupIdx
        for .col from 1 to .nCols
            if .col <> .groupIdx and .dataIdx = 0
                .dataIdx = .col
            endif
        endfor
    endif

    # Ensure factor1 has a value if group was detected
    if .groupIdx > 0 and .factor1Idx = 0
        .factor1Idx = .groupIdx
    endif

    label GUESS_ROLES_DONE
endproc
