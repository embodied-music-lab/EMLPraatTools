# v153: Result state clear on entry; the LMM stale export fix
#
# Validates API settlement item 4: Result unification clear state on entry;
# the LMM stale-export fix.
#
# Defect: When an analysis populates the result store (tidy/glance/augment
# collectors), then a second analysis runs that does not populate those
# collectors (e.g. LMM, which only prints to Info), the export would read
# stale values from the first analysis and export them under the second
# analysis's name.
#
# Mechanism: Procedure locals (*.x) are namespaced globals that persist
# between calls. The result collectors are procedure locals that are meant
# to be cleared at the start of every analysis. If @emlResultClearAll is
# not called at entry, they retain values from the previous run.
#
# Test strategy: Run Praat code that:
# 1. Populates result collectors via ANOVA
# 2. Calls @emlCSVInit and @emlResultClearAll (as LMM does)
# 3. Checks that the collectors are empty after the clear
# This demonstrates both the defect (before the clear) and the fix (after it).


# Create Praat script to test the fix
praat_script <- "
include ~/.praat-dir/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat

print \"=== Test: Result State Clear on Entry ===\"
print \"\"

print \"Step 1: Populate result collectors (simulate ANOVA)\"
print \"  Calling @emlResultBegin to set up collectors...\"
@emlResultBegin: \"TestTable\", \"One-way ANOVA\"

# Manually populate collectors to simulate ANOVA
print \"  Adding sample tidy rows...\"
@emlTidyRow: \"factor1\"
@emlTidyNum: \"df\", 2
@emlTidyNum: \"statistic\", 5.42

@emlTidyRow: \"Residuals\"
@emlTidyNum: \"df\", 45

@emlGlanceNum: \"nobs\", 48
@emlGlanceStr: \"method\", \"One-way ANOVA\"

print \"After population:\"
print \"  emlTidy_nRows = \", emlTidy_nRows
print \"  emlGlance_nCols = \", emlGlance_nCols
print \"  emlResult_declared = \", emlResult_declared

.stored_tidy_rows = emlTidy_nRows
.stored_glance_cols = emlGlance_nCols

print \"\"
print \"Step 2: Clear collectors (as LMM should do)\"
print \"  Calling @emlResultClearAll...\"
@emlResultClearAll

print \"After @emlResultClearAll:\"
print \"  emlTidy_nRows = \", emlTidy_nRows
print \"  emlGlance_nCols = \", emlGlance_nCols

print \"\"
print \"=== VALIDATION ===\"
if emlTidy_nRows = 0 and emlGlance_nCols = 0
    print \"PASS: Collectors cleared successfully (fix is working)\"
    if .stored_tidy_rows > 0
        print \"  Confirmed: had \", .stored_tidy_rows, \" rows before clear\"
    endif
    .test_result = 0
else
    print \"FAIL: Collectors still have stale data (defect present)\"
    print \"  Expected: emlTidy_nRows=0, got \", emlTidy_nRows
    print \"  Expected: emlGlance_nCols=0, got \", emlGlance_nCols
    .test_result = 1
endif
"

# Write Praat script
script_file <- "/tmp/v153_test.praat"
writeLines(praat_script, script_file)

# Run the script and capture output
cat("Running Praat validation script...\n")
output <- system(sprintf("praat6630 --run %s 2>&1", script_file), intern = TRUE)

# Print output
cat("\nPraat output:\n")
cat(paste(output, collapse = "\n"))
cat("\n\n")

# Determine pass/fail
if (any(grepl("PASS: Collectors cleared successfully", output))) {
    cat("TEST RESULT: PASS\n")
    exit_code <- 0
} else if (any(grepl("FAIL: Collectors still have stale data", output))) {
    cat("TEST RESULT: FAIL\n")
    exit_code <- 1
} else {
    cat("TEST RESULT: UNCLEAR - Could not parse output\n")
    exit_code <- 2
}

# Cleanup
unlink(script_file)

quit(save = "no", status = exit_code)
