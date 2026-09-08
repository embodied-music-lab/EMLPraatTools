# ============================================================================
# validate/probes/vectors_to_table_probe.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# FINDING (Fable's ruling, mechanism 1 -- materialise-then-substitute)
#
# Turning a set of script-level Praat vectors into a Table has three
# candidate mechanisms. Two were probed and rejected here; the third is what
# @emlVectorsToTable and @emlToTable (plugin_EML_StatsGraphs/graphs/
# eml-graph-procedures.praat) are built on.
#
#   MECHANISM 1 -- MATERIALISE-THEN-SUBSTITUTE (ACCEPTED). A vector's NAME
#   is passed as a string; Praat's quoted-substitution operator rewrites
#   `.v# = 'name$'` to `.v# = patient#` (whatever `name$` held) BEFORE the
#   line is parsed, so the assignment is an ordinary vector copy the
#   interpreter never sees as indirection. Handles any length, any count,
#   numeric or string vectors, and reports a missing name as an ordinary
#   `.error$` a caller can test -- because `variableExists` is called BEFORE
#   the substitution runs, nothing about it can halt the interpreter.
#   Blocks 1a-1c, 1e.
#
#   ITS ONE SCOPING RULE, WHICH BLOCK 1d MEASURES: Praat resolves a bare
#   `.foo` against whichever procedure is CURRENTLY EXECUTING, not the
#   caller's frame. A name like ".myLocal#", passed down from inside some
#   OTHER procedure, resolves against @emlVectorsToTable's own (empty) frame
#   and is correctly refused as missing -- not silently misread. The
#   procedure-qualified form (`someProc.myLocal#`, the same form every
#   `.result` in this codebase is read back through after `@someProc`
#   returns) IS script-visible and resolves correctly. Hence the header rule:
#   names passed to @emlVectorsToTable must be SCRIPT-LEVEL vectors.
#
#   MECHANISM 2 -- THE RAGGED VECTOR LITERAL, `{ a#, b# }` (REJECTED). Block
#   1f. Praat accepts this literal only when every vector inside it is the
#   same length; on a mismatch it does not raise a script-catchable error --
#   it HALTS THE INTERPRETER outright ("The vectors have to be of the same
#   size, not 2 and 3"), with no `.error$` a procedure could ever set. A
#   caller with two vectors of different lengths -- the exact case
#   @emlVectorsToTable is asked to pad rather than refuse -- could not even
#   reach this procedure's own logic; the whole script would already be
#   dead. Deliberately the LAST block in this file: it halts the run, and
#   that halt IS the finding, not a bug in the probe.
#
#   MECHANISM 3 -- THE OBJECT-BASED ROUTE (REJECTED). Block 1g. Wrap each
#   named vector in its own one-column Table object, then look for a Praat
#   command that joins several Tables column-wise into one wide Table. None
#   exists (`Table: Append` concatenates ROWS of matching-column tables, the
#   opposite shape). Building the join by hand needs the identical
#   cell-by-cell copy mechanism 1 already does, after first paying for N
#   throwaway Table objects and their cleanup -- strictly more machinery for
#   the same result, so there is nothing this route buys over mechanism 1.
#
# HOW TO RUN
#
#   /usr/local/bin/praat6630 --run validate/probes/vectors_to_table_probe.praat
#
# Blocks 1a-1e and 1g print their findings and return normally. Block 1f
# is expected to halt the script with a Praat error -- that is the finding
# it demonstrates, not a probe failure. Every block below was run against
# Praat 6.6.30 to produce the text quoted above and in
# plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat's
# @emlVectorsToTable header; none is reconstructed from memory.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

appendInfoLine: "=== vectors_to_table_probe ==="

# ---- 1a. equal-length numeric vectors, materialise-then-substitute -------
patient# = { 1, 2, 3 }
age# = { 30, 40, 50 }
name$ = "patient#"
appendInfoLine: newline$, "-- 1a: equal-length numeric vectors --"
if variableExists (name$)
    v1# = 'name$'
    appendInfoLine: "  patient# materialised: size=", size (v1#), " values=", v1#
else
    appendInfoLine: "  UNEXPECTED: patient# reported missing"
endif
name$ = "age#"
v2# = 'name$'
appendInfoLine: "  age# materialised: size=", size (v2#), " values=", v2#

# ---- 1b. indexed local vector names via interpolation --------------------
; This is how @emlVectorsToTable holds an arbitrary COUNT of materialised
; vectors as separate locals (.v1#, .v2#, ...) inside one loop, since Praat
; has no vector-of-vectors: the loop index is spliced into the local's own
; name, not used to index into it.
appendInfoLine: newline$, "-- 1b: indexed local names (.v'i'#) --"
names$# = { "patient#", "age#" }
for i to 2
    nm$ = names$# [i]
    v'i'# = 'nm$'
    appendInfoLine: "  v", i, "# (from ", nm$, ") size=", size (v'i'#)
endfor

# ---- 1c. a string vector materialises into a TEXT column -----------------
appendInfoLine: newline$, "-- 1c: string vector --"
cond$# = { "control", "treated", "treated" }
nm$ = "cond$#"
if variableExists (nm$)
    vs$# = 'nm$'
    appendInfoLine: "  cond$# materialised: size=", size (vs$#), " first=", vs$# [1]
else
    appendInfoLine: "  UNEXPECTED: cond$# reported missing"
endif

# ---- 1d. script-level-only scoping: the rule the header states -----------
appendInfoLine: newline$, "-- 1d: script-level-only scoping --"
procedure innerCheck: .n$#
    .nm$ = .n$# [1]
    .found = variableExists (.nm$)
    appendInfoLine: "  from inside innerCheck, name=", .nm$, " variableExists=", .found
endproc

procedure outerHolder
    .myLocal# = { 7, 8, 9 }
    bareNames$# = { ".myLocal#" }
    appendInfoLine: "  calling innerCheck with the BARE local name (should fail to resolve there):"
    @innerCheck: bareNames$#
endproc
@outerHolder

procedure outerHolder2
    .myLocal2# = { 5, 6 }
endproc
@outerHolder2
qualifiedNames$# = { "outerHolder2.myLocal2#" }
appendInfoLine: "  calling innerCheck with the QUALIFIED name (should resolve):"
@innerCheck: qualifiedNames$#

# ---- 1e. a missing name is an ordinary boolean, never a halt -------------
appendInfoLine: newline$, "-- 1e: missing name --"
missingName$ = "nonexistentVector#"
appendInfoLine: "  variableExists(""nonexistentVector#"") = ", variableExists (missingName$)
appendInfoLine: "  (this is exactly what @emlVectorsToTable tests before it ever"
appendInfoLine: "  substitutes, which is why a missing name is a refusal and not a halt)"

# ---- 1g. the object-based route: no column-join exists, no win ----------
appendInfoLine: newline$, "-- 1g: object-based route (rejected on its own terms) --"
t1 = Create Table with column names: "eml_probe_t1", 3, "patient"
for r to 3
    Set numeric value: r, "patient", patient# [r]
endfor
t2 = Create Table with column names: "eml_probe_t2", 3, "age"
for r to 3
    Set numeric value: r, "age", age# [r]
endfor
appendInfoLine: "  two one-column Tables built (", t1, ", ", t2, "); Praat has no"
appendInfoLine: "  command that joins Tables column-wise (""Table: Append"" concatenates"
appendInfoLine: "  ROWS of matching-column tables, the opposite shape) -- joining them"
appendInfoLine: "  by hand still needs mechanism 1's own cell-by-cell copy, after first"
appendInfoLine: "  paying for these two throwaway objects and their cleanup."
removeObject: t1, t2

# ---- 1f. the ragged literal HALTS THE INTERPRETER (deliberately last) ----
appendInfoLine: newline$, "-- 1f: ragged vector literal { a#, b# } -- EXPECTED TO HALT --"
a# = { 1, 2 }
b# = { 1, 2, 3 }
appendInfoLine: "  about to build { a#, b# } with a# size=2, b# size=3 ..."
c# = { a#, b# }
appendInfoLine: "  UNEXPECTED: reached this line; the literal should have halted the script"
