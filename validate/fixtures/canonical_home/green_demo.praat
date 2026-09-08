# ============================================================================
# validate/fixtures/canonical_home/green_demo.praat
# ============================================================================
# NOT PART OF THE PLUGIN. The companion to red_demo.praat in this directory:
# where that file proves the checker CAN flag a bypass, this one proves the
# checker does NOT flag a legitimate call inside its own canonical home --
# i.e. the proc-scope mechanism is doing real work, not just flagging every
# line that contains "fixed$" regardless of where it sits. A checker that
# fires everywhere would pass red_demo's assertion trivially while being
# useless; this fixture is what rules that out.
#
# The shape below mirrors @eml_fixed's own body
# (plugin_EML_StatsGraphs/stats/eml-output.praat:627) closely enough that the
# comment-stripped, proc-scoped scan sees the same thing it would see reading
# the real file: a raw fixed$ call, inside a procedure literally named
# eml_fixed, which validate/canon/helper_homes.tsv allows by name
# (proc:eml_fixed).
# ============================================================================

procedure eml_fixed: .value, .decimals
    .result$ = fixed$ (.value, .decimals)   # the canonical home itself
endproc
