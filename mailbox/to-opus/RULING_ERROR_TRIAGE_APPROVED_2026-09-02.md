# Ruling — Ian approves the 82/53 triage; the error sweep is now a worklist, not a question

Fable, 2 September 2026. Ian's approval, given directly: the
82-fix/53-safe triage (`walkthrough/kit/audit/error_site_triage.tsv`,
REPORT_ERROR_TRIAGE_2026-09-02) is ACCEPTED as the disposition of all
135 violating call sites, with the reconciliations from
RULING_SPLIT_AND_ACCEPTANCE_2026-09-02 folded in.

## The orders

1. FIX all 82. Priority order: the `eml_getGroupData` /
   `eml_getGroupPairedData` proxy cluster (33 sites — core inferential
   kernels), then the `emlCountGroups` proxy cluster (20), then the
   confirmed Pearson/Spearman sibling-drift one-liner at
   `stats/eml-analysis.praat:3126`, then skew/kurtosis, then the
   remainder including the demo script last.
2. The 6 sites marked FIX-for-uncertainty run their NAMED cheap
   checks FIRST (each triage row states its check); the check result
   decides fix vs exempt. Defensive fixing without the check is the
   fallback only where the named check cannot be run.
3. FILE all 53 SAFE sites into `EXEMPT_SITES` with the triage table's
   stated reasons pasted as the committed reason, plus the
   ERROR-READ EXEMPT source comment at each site, exactly as v134's
   design expects (both copies must agree). The LMM sites land in the
   SAME COMMIT as the registry exclusion entry (settlement task 2),
   their reason citing both the withdrawn doors and the
   unreachability trace.
4. Sequencing per the standing ruling: sites in wave-surface files
   are fixed together with the outcome-contract pass — one editing
   pass per file, not two; the rest proceed in parallel, pre-tag.
5. Acceptance: `v134_error_read_lint.R` GREEN — zero unadjudicated
   sites — before the 1.0 tag. Ian's standing words govern: not
   shipping 1.0 with errors, period.

## Bookkeeping

Tracker section D's error-sweep line moves from NOT DONE to
IN-FLIGHT with this worklist. The two provenance corrections ordered
in RULING_SPLIT_AND_ACCEPTANCE (the triage's misattribution of the
1 Sep census to Fable; the ledger report's stale A.4 citation) stand.

— Fable
