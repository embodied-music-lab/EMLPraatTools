# ---------------------------------------------------------------------------
# harness/batchgui/grab.praat — the Info window, as text, out of a live GUI
# ---------------------------------------------------------------------------
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS SOLVES. Everything the batch module tells a user during a run goes
# to the Info window, and after a GUI drive that window is pixels. A screenshot
# is evidence a human can read and a validator cannot, so every claim about the
# warnings would have to be made by eye — which is how the graphs form's Exp
# CSV defect survived a harness that photographed it.
#
# THIS FILE IS SENT INTO THE ALREADY-RUNNING PRAAT, not run in a new one:
#
#     praat --pref-dir=<same> --send grab.praat
#
# `--send` executes in the existing GUI instance, so info$ () returns THAT
# session's Info window — the one the drive just filled. A new instance would
# return an empty string and the leg would report a clean run with no warnings,
# which is the failure shape this whole harness exists to avoid.
#
# THE TARGET PATH ARRIVES AS A SCRIPT ARGUMENT, NOT AS AN ENVIRONMENT
# VARIABLE, and the difference is the whole trap. `--send` executes the script
# in the OTHER process, which was started minutes earlier with its own
# environment; environment$ () there returns what the GUI instance inherited,
# not what the sending shell exported. The first version of this file read
# $EML_BATCHGUI_INFO and got an empty string, exitScript'd inside the live
# session, and left the run reporting a complete drive with no Info evidence at
# all — a green harness with its one machine-readable artefact silently
# missing. A `form` block is filled from the command line by --send without
# being shown, so the value crosses the process boundary the same way the
# script does.
#
# THE FILE COMES BACK AS UTF-16, AND THAT IS NOT A BUG HERE. APPENDIX_F's
# FILE-OUTPUT ENCODING rule (hard): one non-ASCII character makes Praat write
# the entire file as UTF-16 BE even under --utf8, and the module's warnings are
# full of em dashes. run.sh converts on the way out rather than pretending
# otherwise. It is also a live demonstration of the rule, on the plugin's own
# output, which is worth more than the note in the appendix.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------

form: "grab"
    sentence: "Target", ""
endform

if target$ = ""
    exitScript: "grab: no target path was passed."
endif
writeFile: target$, info$ ()
