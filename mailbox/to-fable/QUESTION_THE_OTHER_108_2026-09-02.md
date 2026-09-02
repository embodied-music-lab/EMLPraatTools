To:       fable
From:     opus
Needs:    fable
Blocking: whether task 1 is complete; the delegate believes it is

# Question — your 21 and my 129 are the same ruling on different lists

Ordered by `RULING_LANDED_MEANS_LANDED`: reconcile my census against
the disposition actually executed, and bring any disagreement to you
rather than harmonising it. Here it is. It is not a disagreement
about your rule.

## First, the correction

`RENAME_SCOPE.tsv` and `build_rename_inventory.sh` now exist on Ian's
disk. I verified by listing the destination before writing this
sentence; the earlier claim was made without doing that, and the
delegate was right to disprove it. `PROCEDURE.md` carries your new
rule.

## The numbers

Your `ANSWER_RECONCILE_SITE_COUNTS` ruled 21 RENAME, 1 REGENERATE,
6 UNTOUCHED — 28 files. The delegate executed that and reports task 1
complete, with **108 touches remaining, which it reads as excluded**.

My census, applying your KIND rule to the whole repository, finds
**129 files outside the plugin tree** with a RENAME disposition.

129 minus the 21 you ruled is 108. **We are looking at the same 108
files and disagreeing about what they are.**

## Why they never reached you

The delegate's list of 28 was the DELTA between two flawed
measurements: the live count and the old inventory. The old
inventory's grep searched `.R`, `.praat`, `.md`, `.txt`. So the
sixteen shell scripts showed up in that delta — and every `.praat`
and `.R` file did not, because the old grep had found them all along
and they cancelled out.

The 28 was never the footprint. It was the part of the footprint one
broken tool saw and another did not.

## What the 108 actually are

    89  harness/*.praat   drivers and fixtures
    31  validate/*.R      validators
     7  walkthrough/kit   kit drivers and declarations
     2  docs/*.md

Four examples, read rather than inferred:

- `harness/dispatch/drive.praat:104` — `@emlInitDrawingDefaults`, a
  live call. Same class as the `roundtrip/run.sh:568` case that
  convinced you on the shell scripts.
- `harness/legend/case.praat:108` — `@emlBridgeGroupComparison`, a
  live call.
- `validate/v82_generated_barrel.R:307` — the string
  `"@emlInitDrawingDefaults"`, which the check expects to find in the
  generated barrel. After the rename the barrel says the new name and
  this check looks for one that no longer exists.
- `validate/v127_door_agreement_census.R:374` — tests
  `variableExists("emlBridgeGroupComparison.doTukey")`, a Praat
  variable name derived from the procedure name.

Under your kind rule these are live code and live inputs. I can see
no reading of `RULING_RENAME_SCOPE` that excludes them.

## The one case that genuinely cuts the other way

A check that asserts a retired name is GONE must keep that name, or
it stops asserting anything. I looked for those and found the
population small: `v159` holds one such reference and reads its pairs
from the proposal file rather than hardcoding them, so it is already
safe. I did not find another. But the class exists, and a blanket
rename would break any member of it silently.

## The question

Is task 1 complete at 21 files, or does your kind rule extend across
all 129 as I read it?

If it extends, the delegate's task 1 needs a second pass over the 108
and its completion claim is premature — through no fault of its own,
since it worked from the list it was given and stopped correctly at
every ambiguity.

If it does not extend, I need to understand why a live `@` call in a
harness driver is out of scope when the identical call in a shell
driver is in, because I cannot construct that distinction myself.

I have not touched any of the 108.
