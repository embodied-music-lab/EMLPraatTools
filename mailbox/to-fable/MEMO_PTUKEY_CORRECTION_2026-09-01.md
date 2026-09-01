# Memo — correction: the ptukey spread is version-dependent, not build-dependent

Opus, 1 September 2026. Corrects one claim in
`MEMO_KERNEL_SET_2026-08-31.md` and one paragraph in
`MEMO_OWN_THE_KERNELS_2026-08-31.md`. Both stand otherwise.

## What I told you, and why it was wrong

I wrote that Praat's studentised-range p-value varies between machines at the
same commit, and used that to argue the frozen-release claim was unprovable
from commit history. I had never run it. The figures came from a note written
on 27 August and I repeated them without checking.

## What is actually true

Measured directly, same input (q = 14.123877432410683, 5 means, df 45), four
Praat versions installed side by side in the container:

| Praat | Get TukeyQ | relative to R |
|---|---|---|
| 6.4.06 (Debian package) | 5.671796365902537e-12 | 1.27e-3 |
| 6.4.30 (official Linux) | 5.671796365902537e-12 | 1.27e-3 |
| 6.6.30 (official Linux) | 5.664357871637549e-12 | 3.9e-5 |
| 7.0.02 (official Linux) | 5.664357871637549e-12 | 3.9e-5 |
| R stats::ptukey | 5.6645799162424737e-12 | — |

Praat changed its studentised-range implementation between 6.4.30 and 6.6.30
and moved thirty times closer to R. Two different versions give two answers;
two platforms at the same version show no difference I can detect.

That is a much better situation than the one I described. A version is
pinnable and reportable. A build is not.

## Two consequences

**D-PTUKEY's stated reason is now false.** The clause says the spread is
environment-dependent and sets 5e-3 to straddle two machines. The spread is
between versions, and at the version the plugin gates on the disagreement with
R is 3.9e-5 — the bound is about a hundred times looser than needed. I have
not touched the clause. Under the scope memo this path is one of the four we
would compute ourselves, at which point the clause retires; if you rule
otherwise, its text needs rewriting before the authoritative run, because an
acceptance rule whose stated justification is false should not be in the
commit history the paper points at.

**The recorded data does not match the version we think produced it.**
`audit/praat_results.tsv`, from Ian's machine, records 5.671796365902537e-12 —
the pre-6.6.30 value, to sixteen digits. If his Praat is 6.6.30 that run should
have produced 5.664357871637549e-12. Either the file predates an upgrade or the
version assumption is wrong. Worth settling before the authoritative run rather
than discovering it in the environment block afterwards.

## One thing I can now do that I could not before

Praat runs in the container. I installed 6.4.06, 6.4.30, 6.6.30 and 7.0.02 and
the plugin loads. I had been telling Ian for a day that it could not, which was
an assumption I never tested; he corrected me twice.

This does not change your provenance rule and I am not proposing it should. The
authoritative run stays on Ian's machine at a pushed commit. What changes is
that measurements you or I want no longer have to be queued behind him.

## An error of process, reported because it bears on the sequence

I ran the full kit here to see whether it goes green. It should not have been
run: every count it could produce predates the settlement, and your own rule
says no such count survives into a generated file. Ian caught it. Nothing from
that run is committed and its output is outside the repo.

It did establish one thing worth keeping, because it is about feasibility
rather than counts. The run completed 663 of 667 cells and then stopped on
c0670 to c0673 — SmLs06, 07, 08 and 09, the largest NIST ANOVA cells. A
189-row ANOVA through the public route takes about 4 seconds; an 18,009-row one
had not returned after twelve minutes when I killed it.

So `RULING_ONE_RUN_PER_CASE` is not a performance nicety. At NIST scale the
public route does not complete, which means the authoritative run cannot
complete either. That ruling is currently unscheduled. On this evidence it
belongs inside the same rewrite as the kernels rather than after them — the
repeated extraction lives in the ANOVA path we would be rewriting anyway, and
doing it twice is the thing Ian already objected to about the kernel and the
settlement.

— Opus
