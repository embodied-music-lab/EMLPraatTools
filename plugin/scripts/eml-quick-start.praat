# ============================================================================
# EML Stats & Graphs — Quick Start Guide
# ============================================================================
# Prints a quick-start guide to the Info window.
# Version: 1.1
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

# THE FOLDER NAME IS ASKED FOR, NOT TYPED. The lines below tell a user what to
# put in their own script and where to find the README, so the name they read
# has to be the folder Praat actually installs this plugin into. @emlPluginFolder,
# in stats/eml-record.praat, is where that name is written; every part of the
# plugin that needs it asks the same procedure, so the instruction and the
# installation cannot say different things.
#
# It is that module and not a smaller one because eml-record.praat carries no
# relative include of its own, which is what lets it be included from the
# plugin root, from scripts/, and from a user's own folder alike. `include` is
# a parse-time text paste and cannot take a variable, so the path is written
# out; it resolves against this top-level script's own folder.
include ../stats/eml-record.praat

@emlPluginFolder

writeInfoLine: "============================================================"
appendInfoLine: "  EML Stats & Graphs — Quick Start Guide"
appendInfoLine: "============================================================"
appendInfoLine: ""
appendInfoLine: "TWO WAYS TO USE EML TOOLS"
appendInfoLine: ""
appendInfoLine: "  1. MENU ITEMS (no scripting)"
appendInfoLine: "     Select a Table in the object list, then click one of"
appendInfoLine: "     the EML: action buttons. Fill in the dialog. Results"
appendInfoLine: "     appear in this Info window."
appendInfoLine: ""
appendInfoLine: "  2. IN YOUR OWN SCRIPTS"
appendInfoLine: "     Add these includes at the top of your script:"
appendInfoLine: ""
appendInfoLine: "       include ", emlPluginFolder.name$, "/stats/eml-core-utilities.praat"
appendInfoLine: "       include ", emlPluginFolder.name$, "/stats/eml-core-descriptive.praat"
appendInfoLine: "       include ", emlPluginFolder.name$, "/stats/eml-extract.praat"
appendInfoLine: "       include ", emlPluginFolder.name$, "/stats/eml-output.praat"
appendInfoLine: "       include ", emlPluginFolder.name$, "/stats/eml-inferential.praat"
appendInfoLine: ""
appendInfoLine: "     Then call procedures directly. Example:"
appendInfoLine: ""
appendInfoLine: "       group1# = {195, 210, 188, 203, 197}"
appendInfoLine: "       group2# = {165, 172, 158, 180, 163}"
appendInfoLine: "       @emlTTest: group1#, group2#, 2, 0"
appendInfoLine: "       @emlFormatP: emlTTest.p"
appendInfoLine: "       appendInfoLine: fixed$(emlTTest.t, 2)"
appendInfoLine: ""
appendInfoLine: "------------------------------------------------------------"
appendInfoLine: "  AVAILABLE TESTS"
appendInfoLine: "------------------------------------------------------------"
appendInfoLine: ""
appendInfoLine: "  Descriptive:   @emlDescribe"
appendInfoLine: "  Two-group:     @emlTTest, @emlTTestPaired"
appendInfoLine: "                 @emlMannWhitneyU, @emlWilcoxonSignedRank"
appendInfoLine: "  Effect sizes:  @emlCohenD, @emlRankBiserialR,"
appendInfoLine: "                 @emlMatchedPairsR"
appendInfoLine: "  Correlation:   @emlPearsonCorrelation,"
appendInfoLine: "                 @emlSpearmanCorrelation"
appendInfoLine: "  k-group:       @emlOneWayAnova, @emlTwoWayAnova,"
appendInfoLine: "                 @emlKruskalWallis"
appendInfoLine: "  Post-hoc:      @emlTukeyHSD, @emlPairwiseT,"
appendInfoLine: "                 @emlPairwiseWilcoxon, @emlDunnTest,"
appendInfoLine: "                 @emlScheffe"
appendInfoLine: "  p-adjustment:  @emlBonferroni, @emlHolm,"
appendInfoLine: "                 @emlBenjaminiHochberg"
appendInfoLine: ""
appendInfoLine: "------------------------------------------------------------"
appendInfoLine: "  DOCUMENTATION"
appendInfoLine: "------------------------------------------------------------"
appendInfoLine: ""
appendInfoLine: "  Overview:             README.md (in the plugin folder)"
appendInfoLine: "  Demo figure:          Run Stats Demo (in EML Stats & Graphs menu)"
appendInfoLine: ""
appendInfoLine: "  README.md is in the ", emlPluginFolder.name$, " folder inside"
appendInfoLine: "  your Praat preferences directory."
appendInfoLine: ""
appendInfoLine: "============================================================"
appendInfoLine: "  Framework: Ian Howell, Embodied Music Lab"
appendInfoLine: "  www.embodiedmusiclab.com"
appendInfoLine: "============================================================"
