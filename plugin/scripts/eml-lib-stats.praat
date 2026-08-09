# ============================================================================
# eml-lib-stats.praat — the statistics stack, in dependency order.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#     include eml-lib-stats.praat
#
# instead of the five lines this replaces. Load this when a script needs to
# compute but not to draw.
#
# TWO THINGS ABOUT PRAAT'S `include` THAT CONSTRAIN THIS FILE
#
# 1. A relative path inside an included file resolves against the TOP-LEVEL
#    script's directory, not against the file the line is written in. That is
#    why this barrel lives in scripts/ next to the scripts that use it, and
#    why the paths below read "../stats/..." — they are written from the
#    caller's point of view, not from this file's.
#
# 2. Including the same file twice is harmless. `include` is a textual paste
#    at parse time and a second definition of a procedure silently replaces
#    the first, so no include guard is needed and the layered barrels below
#    can overlap freely.
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

include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-output.praat
include ../stats/eml-inferential.praat
include ../stats/eml-result-writer.praat
; The recorder defines procedures and touches nothing at include time --
; @emlRecordInit is idempotent and every entry point returns immediately
; while emlRecordActive is 0. So loading it here costs a parse and no
; behaviour, and a wrapper that never records is unaffected.
include ../stats/eml-record.praat
