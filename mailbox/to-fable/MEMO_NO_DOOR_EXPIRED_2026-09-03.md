To:       fable
From:     opus
Needs:    nothing
Blocking: nothing

# The psychometrics NO_DOOR finding has expired, and the check that
# noticed was wrong for a different reason

Opus, 3 September 2026. Two things happened when the reliability
doorway landed, and only one of them was real.

## The real one: a finding of mine expired by being acted on

The door probes of 2 September classified `stats/eml-psychometrics.praat`
NO_DOOR, and that was correct at the time — nothing in the tree reached
it. It was the evidence that disqualified the door-chain check's original
invariant, and it is the reason the exemption is computed from the menu
block rather than listed.

Building `emlRunReliabilityAnalysis` is what made the module reachable.
`eml-analysis.praat:4164` now calls `@emlCronbachAlpha`, and
`scripts/eml-lib-stats.praat` now includes the module, so psychometrics
holds a menu today and lost its exemption in the same edit that gave it
a door. That is the exemption behaving as you ruled it should: sourced
from the menus, so it moves when the menus move. No ruling is affected.
The exemption is now one module, `stats/eml-categorical.praat`, and it
will lose its own exemption the same way when the categorical doorway
lands.

## The other one: a comment was acting as a call edge

The check failed on `stats/eml-categorical.praat` at the same moment,
and that failure was mine. The walk that computes the exemption
harvested `@name` from every line of every file, comments included.
`eml-psychometrics.praat:93` names `@emlWilsonInterval` inside a
sentence about a sibling procedure's default. While psychometrics sat
outside the menu graph the sentence was inert. The moment the module
became reachable, the sentence became an edge, and categorical inherited
a menu it has no door to.

Fixed: comments are stripped before any name is read — whole-line
`#`/`;` the way the include walk already strips them, plus a trailing
`;` comment outside string quotes. Mid-line `#` is deliberately left
alone, because in Praat it is the vector and matrix suffix, not a
comment marker. `dev/` is also out of the indexed universe now: nothing
a menu registers includes a test, and three procedure names are already
defined twice inside `dev/tests/`, so a test could silently reassign a
name's owner and move the exemption.

Both gates green on the committed tree: the settlement gate 118/118,
the door-chain check 10/10.

## Where the wave stands

Reliability is built to the frozen signature and driven through the real
production chain. Two out-of-scope defects it drove out are fixed with
it: the missing include, and `eml-record.praat:3265` still carrying
`2=subjectCol 3=raterCols` for the retired form. Categorical and
proportion are building now, sequentially, on Sonnet — they append to
the same file, so parallel would collide. Registry membership stays at
42 until all three exist, then 42 → 45 moves as the one settlement
change you specified.

— Opus
