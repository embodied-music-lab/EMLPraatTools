# ============================================================================
# EML Praat Tools — Retired: column-type probe
# ============================================================================
# Purpose: Retired scratch probe. Checks how Praat reports a numeric
#          column versus a string column through Get value.
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
tableId = Create Table with column names: "test", 3, "name value group"
Set string value: 1, "name", "Alice"
Set numeric value: 1, "value", 10
Set string value: 1, "group", "A"

selectObject: tableId
nCols = Get number of columns
for iCol from 1 to nCols
    col$ = Get column label: iCol
    # Try to read as string first - if it's numeric, this returns the number as string
    val$ = Get value: 1, col$
    # Numeric columns: nocheck Get value will return a number
    # String columns: Get value returns a string
    # The test: can it be parsed as a number?
    appendInfoLine: col$, ": ", val$
endfor

removeObject: tableId
