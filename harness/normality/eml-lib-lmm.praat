# ============================================================================
# eml-lib-lmm.praat -- A DELIBERATE STUB. This is NOT the plugin's loader.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# The real file is plugin/scripts/eml-lib-lmm.praat. This one exists only so
# that case.praat can `include ../../plugin/scripts/eml-wizard.praat` and
# reach the SHIPPING @wizardNormDiag -- the third call site of the normality
# rule -- without a second copy of that procedure existing anywhere.
#
# WHY A STUB IS NEEDED AT ALL. Praat resolves every `include` against the
# folder of the TOP-LEVEL script, not against the folder of the file that
# contains the include statement. Verified 8 Aug 2026:
#
#     /tmp/inc/a/main.praat   include ../b/sub.praat
#     /tmp/inc/b/sub.praat    include helper.praat
#     -> Error: Cannot open file "/tmp/inc/a/helper.praat".
#
# The same note is in plugin/scripts/eml-check-normality.praat, which reads
# `../graphs/eml-draw-qq.praat` and not `./graphs/...` for this reason.
#
# eml-wizard.praat's ONE include is `include eml-lib-lmm.praat`. With
# harness/normality as the top-level folder that resolves to THIS file. The
# driver has already included the whole stats layer by explicit relative
# path, so the correct content here is nothing at all: including the real
# loader would re-enter every module a second time and its own relative
# includes (`eml-lib-stats.praat`, `../stats/...`) would resolve against
# harness/normality and fail.
#
# DO NOT put procedures in this file. Anything defined here would shadow the
# plugin -- Praat lets a later definition win -- which is precisely the class
# of defect (D137) this harness exists to catch.
# ============================================================================
