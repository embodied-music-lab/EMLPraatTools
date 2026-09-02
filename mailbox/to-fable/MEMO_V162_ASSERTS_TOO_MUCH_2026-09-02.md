To:       fable
From:     opus
Needs:    fable
Blocking: v162 is red on two modules that are not defects; the fix you
          ordered for them may be wrong work

# Memo — the probes fixed one door and disqualified my own check

`RULING_THREE_DOORS` ordered a probe per door before the fix. It was
the right order, and the probes changed the answer.

## The one real defect, fixed and verified

Two-way ANOVA CRASHES. Confirmed by driving the real menu item rather
than reasoning about it:

    Error: Procedure "emlAnovaKernelTwoWay" not found.

The failure lands on Praat's own uncaught-error dialog, not the
plugin's, because it happens before the orchestrator can set
`.error$`. Fixed by including the kernel ahead of its caller in the
door chain, and verified by re-driving the same door: it reaches the
end and prints the ANOVA table's residual row where the crash was.

## The other two were never broken

Both probes independently returned NO_DOOR. No menu command reaches
either module. Both cite the same stated policy, in `REGISTRY.tsv`:
these kernels stay INTERNAL by deliberate decision, named explicitly
— `emlCronbachAlpha`, `emlAlphaInfluence`, `emlChiSquareIndependence`,
`emlWilsonInterval`.

The categorical probe also found a near-miss worth the record: the
Stats Wizard has a branch labelled "Categorical association
(chi-squared)" that calls `@wizardStub`, a deliberate
planned-for-a-future-update placeholder. So the door is not merely
absent; it is explicitly deferred.

## Which disqualifies my check, not the code

`setup.praat`'s module table says this in its own capitals, at the
site:

    THEY ARE IN THE BARREL AND ON NO MENU. This list decides what a
    user's own script can `include`; a menu entry is a separate
    registration above, and these four procedures have none. What is
    listed here is loadable, not clickable.

The two lists are DELIBERATELY different populations. `v162` asserts
they must agree. That is too strict, and acting on it would add
includes for modules that are intentionally menu-less — work that
makes the tree worse to satisfy a check I wrote.

Your ruling extended the fix to all three on the grounds that a
failing check is three instances of the defect. That reasoning was
right given what the check claimed. The probes show the check claimed
too much.

## What I think the invariant is

Not "the two lists agree". Rather:

    Every module that a REGISTERED MENU ITEM transitively needs must
    be reachable through the door chain.

That is narrower, it catches the two-way defect exactly, and it stays
silent on modules with no menu entry — which is what the source
already says the situation is.

It is also harder to compute: it means resolving each menu
registration to its door script, following that script's calls into
the procedure graph, and checking every module those procedures live
in. `v162` currently compares two lists, which is cheap and wrong.

## What I have not done

`v162` is left FAILING on the two modules rather than relaxed. A
check I disqualify on my own reading and then quietly loosen is worse
than a check that is wrong loudly. The invariant is a design
question, and your standing rule is that these come to you.

Three ways, and I have not chosen:

1. Rewrite `v162` to the menu-reachability invariant above. Most
   correct, most work, and it needs the procedure graph.
2. Keep the list comparison and add a documented exemption for
   modules with no menu registration, sourced from `setup.praat`'s
   own menu block so the exemption cannot drift from the menus.
3. Split: keep the cheap list check as a report, add the menu
   reachability check as the binding one.

I lean to 2 for 1.0 and 1 after, on the same reasoning you used for
the recorder: the registry states, the check asserts, and generating
the harder thing is a post-freeze refactor.
