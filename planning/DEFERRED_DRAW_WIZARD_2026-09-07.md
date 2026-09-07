# Deferred: draw and wizard paths (logged for a later phase)

Per Ian (6 Sep): the current freeze scope is the kit and the public API. The
wizard, the menu forms, and the drawing paths are a later phase. This file
collects the items that phase owns, so nothing found during the freeze is lost.

## Frozen-choice disclosure gap (v116)

The `validate/v116_frozen_choice_conformance.R` gate reports one reddened site
(`1 reddened`, of 7 frozen-choice candidates; the other 6 are disclosed and the
gate's seeded negative test is caught):

    emlDunnTest  .correction$  door = wizard:group draw (wizDrawSource$ = "group")
                 literal = holm (graphs form default)   RED -- undisclosed

When the wizard's group-draw path reaches `emlDunnTest`, the pairwise correction
is pinned to `holm` as the graphs-form default but that choice is not disclosed
in the output the user sees. Every non-draw sibling of this correspondence
discloses its frozen choice (tiers A–C); this one draw door does not.

This is not a kit or public-API regression — the kit does not exercise the
wizard group-draw door, and the golden run is bit-identical. It is a
wizard/draw disclosure gap, in the deferred scope. The fix is to disclose the
pinned correction in the wizard draw report (as the sibling doors do), then
confirm v116 goes to `0 reddened`.

## SS-type selection UI (from SSTYPE_DOOR_DEFERRED_2026-09-06)

The two-way ANOVA SS-type control landed for the kit and the public API only.
The menu form (`scripts/eml-compare-twoway.praat`) and the wizard
(`scripts/eml-wizard.praat`) still pass Type III as a keep-alive. This phase
adds an SS-type optionmenu (default III) to both, plus the selected-type naming
in the report. See that file for the full SS-type deferral list (per-type kit
cells, dev tests, Table S2 / settlement-gate / coverage-map regeneration).

## Note on in-container validator runs

The `validate/run_all.R` suite, run in this cloud container, SKIPs the
Praat-driven validators (13 SKIPs on the last partial run) because the harness
does not detect a Praat >= 6.6.30 on its search path here, and the run itself
has twice been interrupted mid-suite by container suspension (reached ~v150 of
156). The authoritative full-suite pass/fail for the paper is a run on Ian's
machine at a pushed commit (now possible: origin/main is at the freeze work).
The gates that DO run in-container (e.g. v134 error-read lint: 0 unadjudicated,
seeded caught) are green.
