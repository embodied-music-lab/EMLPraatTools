# ============================================================================
# pergroup_case.praat -- load one harness table and hand it to the SHIPPING
#                        Check Normality wrapper. D137.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Launched by pergroup.sh into a full-GUI Praat instance. It does two things
# and nothing else: read out/data/<case>.csv back off disk, and `runScript:`
# plugin/scripts/eml-check-normality.praat with that Table selected. Every
# dialog after that is driven by xdotool and every number that comes out is
# the wrapper's own.
#
# THE TABLE IS READ BACK, NOT REBUILT. case.praat wrote it; this reads the
# same file; validate/v32_normality_parity.R reads the same file again. The
# claim under test is that per-group mode and overall mode agree ON THE SAME
# DATA, and two constructions of "the same" numbers is not that claim.
#
# `runScript:` rather than `include`: the wrapper's own `include
# eml-lib.praat` and `include ../graphs/eml-draw-qq.praat` resolve against
# the TOP-LEVEL script's folder, and runScript makes the wrapper the
# top-level. Included from here they would resolve against harness/normality
# and fail. Verified 8 Aug 2026.
#
# Env:
#   EML_NORM_CSV   absolute path of the table to load
# ============================================================================

csv$ = environment$ ("EML_NORM_CSV")
if csv$ = ""
    exitScript: "pergroup_case.praat: set EML_NORM_CSV"
endif

tid = Read Table from comma-separated file: csv$
selectObject: tid

; Cleared HERE and not through the wrapper's own "Clear Info window" field:
; that field is part of what is under test, and a harness must not set it to
; get its own capture clean.
clearinfo

runScript: "../../plugin/scripts/eml-check-normality.praat"
