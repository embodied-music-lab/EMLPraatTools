# ============================================================================
# harness/drawlayer/pergroup_case.praat — hand one table to the SHIPPING
#                                         Check Normality wrapper
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Launched by pergroup_gui.sh into a full-GUI Praat instance. It does two
# things and nothing else: read the fixture back off disk, and `runScript:`
# plugin/scripts/eml-check-normality.praat with that Table selected. Every
# dialog after that is driven by xdotool and every number that comes out is
# the wrapper's own.
#
# WHY A GUI INSTANCE AT ALL. The per-group branch of that wrapper is not a
# procedure — it is inline in a script whose first statement is `beginPause:`,
# and `praat --run` cannot open a display connection, so the branch cannot be
# reached headlessly. Re-implementing its four report lines in a harness would
# be a copy of the thing under test, which is exactly the defect D137 was.
#
# `runScript:` rather than `include`: the wrapper's own `include
# eml-lib.praat` and `include ../graphs/eml-draw-qq.praat` resolve against the
# TOP-LEVEL script's folder, and runScript makes the wrapper the top level.
#
# Env:
#   EML_DL_CSV   absolute path of the table to load
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

csv$ = environment$ ("EML_DL_CSV")
if csv$ = ""
    exitScript: "pergroup_case.praat: set EML_DL_CSV"
endif

tid = Read Table from comma-separated file: csv$
selectObject: tid

; Cleared HERE and not through the wrapper's own "Clear Info window" field:
; that field is part of what is under test, and a harness must not set it to
; get its own capture clean.
clearinfo

runScript: "../../plugin/scripts/eml-check-normality.praat"
