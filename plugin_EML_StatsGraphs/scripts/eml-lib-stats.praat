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
; The psychometrics kernels, which emlRunReliabilityAnalysis calls once that
; doorway exists. Added 3 September 2026 with the doorway itself. Before this,
; the module sat in setup.praat's table -- so a user's own script could load it
; from the generated barrel -- while the hand-maintained chain the doors follow
; never named it. The reliability doorway therefore worked in a scratch harness
; and failed through the real chain with:
;
;     Error: Procedure "emlCronbachAlpha" not found.
;
; That is the same defect as the two-way kernel below, found the same way, one
; day later. The door probes of 2 September classified this module NO_DOOR and
; were right at the time: nothing reached it. Building the doorway is what made
; it reachable, so the classification expired the moment the doorway landed.
include ../stats/eml-psychometrics.praat

; The two-way kernel, which eml-inferential.praat calls at its line 5259 and
; which nothing included. Added 2 September 2026 under
; RULING_RECORDER_AND_WIRING_2026-09-02.md after a probe drove the real menu
; item and reproduced what a user hits:
;
;     Error: Procedure "emlAnovaKernelTwoWay" not found.
;     Script line 17003 not performed or completed:
;     « @emlAnovaKernelTwoWay: .tableId, .dataCol$, .factor1$, .factor2$, 3 »
;
; The failure lands on Praat's own uncaught-error dialog rather than the
; plugin's, because it happens before the orchestrator can set .error$. The
; module was in setup.praat's table all along, so the generated barrel could
; load it and a user's own script worked; only the menu route was broken.
;
; It goes BEFORE eml-inferential.praat because an include is a parse-time
; paste and the caller must find the procedure already defined.
; The studentized-range port, which both kernels below now call for every
; Tukey and Games-Howell leg. Added 4 September 2026 with the repointing
; wave. setup.praat's barrel has carried this module at position 5 of 15
; since the port was written; this chain never named it, so the moment the
; kernels stopped calling Praat's builtin the one-way ANOVA post-hoc door
; died at parse time with
;
;     Error: Procedure "emlStudentizedRangeQ" not found.
;
; Fourth instance of this defect: eml-psychometrics.praat, eml-anova-kernel
; .praat and eml-categorical.praat each arrived the same way, and the
; recorder's own emitted-script include list carried the same gap. A module
; a kernel calls has to be in the chain the doors follow.
include ../stats/eml-studentized-range.praat

include ../stats/eml-anova-kernel.praat
; The Wilcoxon interval module, which eml-inferential.praat's
; @emlHodgesLehmannPaired delegates to for its normal-approximation branch
; (RULING_HL_FIX_WIRED_2026-09-04.md). Added 5 September 2026. The module
; joined setup.praat's barrel table when the delegation was wired, so the
; barrel-population check went green by reachability with no exclusion
; entry -- but barrel membership is not door reachability, and this chain
; never named it, so the delegated call would have died at parse time with
;
;     Error: Procedure "emlWilcoxonIntervalApprox" not found.
;
; Fifth instance of this defect: eml-psychometrics.praat, eml-anova-kernel
; .praat, eml-categorical.praat, and eml-studentized-range.praat above each
; arrived the same way. It goes before eml-inferential.praat for the same
; reason as the line above it: an include is a parse-time paste and the
; caller must find the procedure already defined.
include ../stats/eml-wilcoxon-interval.praat
include ../stats/eml-inferential.praat

; The categorical kernel (@emlChiSquareIndependence, @emlWilsonInterval),
; which emlRunCategoricalAnalysis calls now that doorway exists (3 September
; 2026). Same defect as the two-way kernel and the psychometrics kernel
; above, found the same way: the module has sat in setup.praat's manifest
; table since 17 August with nothing in the hand-maintained chain naming it,
; so it loaded only in the dev test that includes it directly
; (dev/tests/phase2/test-categorical.praat) and in the reproduction-script
; generator (eml-record.praat), never through scripts/eml-lib.praat. A probe
; through the real chain would have hit
;
;     Error: Procedure "emlChiSquareIndependence" not found.
;
; the moment the new doorway called it. It goes before eml-analysis.praat
; (included next, by eml-lib.praat) for the same reason the two lines above
; do: an include is a parse-time paste and the caller must find the
; procedure already defined.
include ../stats/eml-categorical.praat

include ../stats/eml-result-writer.praat
; The recorder defines procedures and touches nothing at include time --
; @emlRecordInit is idempotent and every entry point returns immediately
; while emlRecordActive is 0. So loading it here costs a parse and no
; behaviour, and a wrapper that never records is unaffected.
include ../stats/eml-record.praat
; The demo table builders. Definitions only, like the recorder above it: the
; procedure runs when a caller asks for a demo table and at no other time.
; A recorded script includes it for the same reason a wrapper does -- a create
; step calls @emlDemoTable to rebuild the table the session was recorded on.
include ../stats/eml-demo-tables.praat
