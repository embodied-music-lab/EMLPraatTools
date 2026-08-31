# ============================================================================
# RUN_ME_PETERSON_BARNEY_EXPORT.praat -- STANDALONE, ONE STEP, PRAAT ONLY.
#
# Creates Praat's bundled Peterson & Barney (1952) formant table via the
# built-in `Create formant table (Peterson & Barney 1952)` command, saves it
# tab-separated into data/, and prints the row and column count so the
# export can be checked by eye before anything downstream reads it.
#
# WHY THIS EXISTS: the two-way ANOVA kernel's canonical red-demo case is
# Praat's own manual example -- the two-way ANOVA of a formant frequency by
# Vowel x Type on the Peterson-Barney data, where the built-in `Report
# two-way anova` prints Error SS 1,600,534 (correct: 914,449) and vowel
# F 7.625 (correct: 13.346). See
# mailbox/to-opus/WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md. That table is not
# shipped as a file anywhere in this repo -- it exists only as a Praat
# built-in generator, so it can only be produced on a machine Praat is
# installed on. This container has no Praat; this script was written and
# reviewed there but has NOT been run anywhere -- its printed row/column
# count is the first real check of it.
#
# RUN THIS DIRECTLY in Praat (Open Praat script..., then Run). No include,
# no dependency on the plugin or on RUN_ME_FIRST.praat.
#
# PLAIN RELATIVE PATHS, THE SAME RULE RUN_ME_FIRST.praat DEPENDS ON: Praat
# resolves "data/..." below against THIS SCRIPT'S OWN FOLDER, not the
# working directory it was launched from. Keep this file in walkthrough/kit/
# itself, beside data/, exactly where RUN_ME_FIRST.praat already lives.
#
# OUTPUT: data/peterson_barney_1952.tsv -- tab-separated, header row, one
# row per vowel token (the manual's dataset is 1,520 rows). Column set is
# whatever Praat's built-in table ships; printed below so a mismatch is
# visible immediately rather than discovered downstream by
# twoway_red_demo/peterson_barney_canonical_check.R, which reads this exact
# path and factor/column names it expects (Vowel, a Type/Sex-like grouping
# factor, and an F1-like formant column) -- if this script's printed column
# list does not contain something recognizable as those, say so before
# handing the file off; that R script is written to fail loudly rather than
# guess quietly if it can't find them either.
# ============================================================================

createFolder: "data"

petersonBarneyTable = Create formant table (Peterson & Barney 1952)

petersonBarneyNRows = Get number of rows
petersonBarneyNCols = Get number of columns
petersonBarneyCols$ = ""
for petersonBarneyC to petersonBarneyNCols
    petersonBarneyColName$ = Get column label: petersonBarneyC
    if petersonBarneyC > 1
        petersonBarneyCols$ = petersonBarneyCols$ + ", "
    endif
    petersonBarneyCols$ = petersonBarneyCols$ + petersonBarneyColName$
endfor

Save as tab-separated file: "data/peterson_barney_1952.tsv"

writeInfoLine: "Peterson & Barney (1952) table exported."
appendInfoLine: "  rows: " + string$ (petersonBarneyNRows)
appendInfoLine: "  columns (" + string$ (petersonBarneyNCols) + "): " + petersonBarneyCols$
appendInfoLine: "  file: data/peterson_barney_1952.tsv"
appendInfoLine: ""
appendInfoLine: "Expected 1520 rows (the manual's bundled dataset). If the row"
appendInfoLine: "count above differs, say so before running the R side --"
appendInfoLine: "twoway_red_demo/peterson_barney_canonical_check.R reads this"
appendInfoLine: "exact path and expects to find a Vowel-like factor, a"
appendInfoLine: "Type/Sex-like factor, and an F1-like numeric column among the"
appendInfoLine: "names printed above."

selectObject: petersonBarneyTable
Remove
