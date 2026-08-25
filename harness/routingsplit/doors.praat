# ============================================================================
# harness/routingsplit/doors.praat — the DISCLOSURE / EXPLANATION split,
#                                     driven rather than read
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS IS FOR. The language batch (LANGUAGE_BATCH_2026-08-25.md,
# revision 3's routing pass) classifies every user-facing line either
# DISCLOSURE — prints on every path, because it states what was or was not
# computed — or EXPLANATION — prints only where the explanations routing
# turns it on. The rule the split exists to enforce is one sentence: A FACT A
# USER NEEDS IS NEVER CARRIED BY A LINE THE TOGGLE CAN REMOVE.
#
# harness/explaingate and harness/explainwiring each prove that ONE named
# sentence appears or disappears. Neither answers the general question, which
# is the one the ruling actually states: over the WHOLE report, on every
# analysis this plugin has, is everything the toggle removes free of fact?
# This rig drives that question. It captures every orchestrator's report
# twice — once with the menu dialog's toggle off, once with it on, through
# the real @emlHandleCommonFields both times — and hands both to
# validate/v132_routing_split.R, which subtracts one from the other and
# inspects what the subtraction removed.
#
# ONE LEG PER PROCESS, chosen by $EML_RS_LEG, so nothing but that leg's own
# appendInfoLine calls reach the captured file — the same idiom as
# harness/explaingate/doors.praat and harness/explainwiring/doors.praat.
#
# THE LEG NAME IS <analysis>_<off|on>. The trailing word is the toggle's
# answer, fed to @emlHandleCommonFields exactly as a real endPause would
# leave it; everything before it selects the analysis.
#
# THE NON-SIGNIFICANT FIXTURE IS DELIBERATE. fixture_flat.csv's three groups
# overlap, so the omnibus does not reach alpha and @emlPostHocCaution (lane
# 3.3, language batch item 11 — EXPLANATION) has something to say. Without a
# fixture like it, the caution line is never printed on any leg and the
# routing of the single most consequential EXPLANATION line in the round
# would go unexamined while every check passed.
#
# Usage (run.sh does this):
#   cd harness/routingsplit
#   EML_RS_LEG=anova_tukey_on praat --run doors.praat > out/anova_tukey_on.txt
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat

Text writing preferences: "UTF-8"

leg$ = environment$ ("EML_RS_LEG")
if leg$ = ""
    exitScript: "routingsplit: EML_RS_LEG is not set."
endif

emlGroupSortAlphabetical = 0

appendInfoLine: "== LEG ", leg$, " =="

; ---------------------------------------------------------------------------
; THE TOGGLE, THROUGH THE REAL DOOR. Both legs go through
; @emlHandleCommonFields — the shared post-endPause handler every menu
; wrapper calls — so what is being exercised is the production routing and
; not a hand-set global. The only difference between the two legs of a pair
; is the value a real endPause would have left in
; annotate_results_with_explanations.
; ---------------------------------------------------------------------------
clear_Info_window = 0
if endsWith (leg$, "_off")
    annotate_results_with_explanations = 0
    analysis$ = left$ (leg$, length (leg$) - 4)
elsif endsWith (leg$, "_on")
    annotate_results_with_explanations = 1
    analysis$ = left$ (leg$, length (leg$) - 3)
else
    exitScript: "routingsplit: leg '", leg$, "' ends in neither _off nor _on."
endif
@emlHandleCommonFields

if analysis$ = "twogroup_both"
    tableId = Read Table from comma-separated file: "fixture_two.csv"
    @emlRunTwoGroupAnalysis: tableId, "Loud", "Voice", "both", 0

elsif analysis$ = "anova_tukey"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunAnovaAnalysis: tableId, "Loud", "Voice", 1

elsif analysis$ = "anova_only"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunAnovaAnalysis: tableId, "Loud", "Voice", 0

elsif analysis$ = "kw_dunn"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunKWAnalysis: tableId, "Loud", "Voice", 1, "holm"

elsif analysis$ = "kw_only"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunKWAnalysis: tableId, "Loud", "Voice", 0, "holm"

elsif analysis$ = "pairwise_welch"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunPairwiseAnalysis: tableId, "Loud", "Voice", "welch", "holm"

elsif analysis$ = "pairwise_wilcoxon"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunPairwiseAnalysis: tableId, "Loud", "Voice", "wilcoxon", "bh"

elsif analysis$ = "correlation_both"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunCorrelationAnalysis: tableId, "Pitch", "Loud", "both"

elsif analysis$ = "regression"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunRegressionAnalysis: tableId, "Loud", "Pitch"

elsif analysis$ = "descriptive"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunDescriptiveAnalysis: tableId, "Loud"

elsif analysis$ = "normality"
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunNormalityAnalysis: tableId, "Loud", "shapiro"

elsif analysis$ = "twogroup_welch"
    tableId = Read Table from comma-separated file: "fixture_two.csv"
    @emlRunTwoGroupAnalysis: tableId, "Loud", "Voice", "parametric", 0

elsif analysis$ = "twogroup_mwu"
    tableId = Read Table from comma-separated file: "fixture_two.csv"
    @emlRunTwoGroupAnalysis: tableId, "Loud", "Voice", "nonparametric", 0

elsif analysis$ = "paired_both"
    tableId = Read Table from comma-separated file: "fixture_rm.csv"
    @emlRunPairedAnalysis: tableId, "pre", "post", "both"

elsif analysis$ = "rmanova"
    tableId = Read Table from comma-separated file: "fixture_rm.csv"
    @emlRunRepeatedMeasuresAnalysis: tableId, "Subject", "pre|mid|post", 1, "holm"

elsif analysis$ = "friedman"
    tableId = Read Table from comma-separated file: "fixture_rm.csv"
    @emlRunFriedmanAnalysis: tableId, "Subject", "pre|mid|post", 1, "holm"

; --- THE NON-SIGNIFICANT OMNIBUS, WITH A POST-HOC THE USER CHOSE -----------
; Lane 3's ruling: a post-hoc the user chose always runs. Lane 3.3: when the
; omnibus did not reach alpha, the report gains the caution line — which is
; EXPLANATION-routed, so the omnibus p it is talking about had better still
; be on the page with the toggle off. That is the single sharpest instance
; of this rig's whole question, which is why both doors get their own leg.
elsif analysis$ = "caution_anova"
    tableId = Read Table from comma-separated file: "fixture_flat.csv"
    @emlRunAnovaAnalysis: tableId, "Loud", "Voice", 1

elsif analysis$ = "caution_kw"
    tableId = Read Table from comma-separated file: "fixture_flat.csv"
    @emlRunKWAnalysis: tableId, "Loud", "Voice", 1, "holm"

elsif analysis$ = "caution_pairwise"
    tableId = Read Table from comma-separated file: "fixture_flat.csv"
    @emlRunPairwiseAnalysis: tableId, "Loud", "Voice", "student", "bonferroni"

else
    exitScript: "routingsplit: unrecognised analysis '", analysis$, "'"
endif

appendInfoLine: "== END ", leg$, " =="
