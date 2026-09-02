# Verify — how to prove the work is done

The gate is `validate/v159_settlement_gate.R`. It reads the six rename pairs
from the accepted proposal rather than restating them, so it cannot drift
from the ruling.

## The bar

```bash
cd ~/EMLPraatTools
Rscript validate/v159_settlement_gate.R
```

Tasks 1 through 3 are done when this reports every binding check passing.
Before you start it reports 24 checks, 1 passed, 23 failed.

Section E of the gate is report-only and does not need to pass. It measures
the recorder against the registry, which is a proposal awaiting a ruling.
Include its output in your report so the ruling has current numbers.

## Do not weaken the gate

The gate is the check on your own work, so changing it is the one edit that
would let a failure through unnoticed. Do not edit
`validate/v159_settlement_gate.R`, and do not edit
`mailbox/to-fable/PROPOSAL_CANONICAL_NAMES_2026-09-01.md`, which the gate
reads its rename pairs from.

If you believe the gate is wrong, write that in `out/REPORT.md` with the
evidence, and leave the gate as it is.

## The rest of the suite

The rename touches procedures the whole suite calls, so a green gate alone
is not enough:

```bash
Rscript validate/run_all.R 2>&1 | tail -30
```

Report the pass and fail counts before and after your change. Any validator
that passed before and fails after is yours to fix or to report, not to
ignore.

## The recorder end to end

```bash
bash harness/record_e2e/run.sh
cat harness/record_e2e/out/RECORD.tsv
```

Report the operation count. Before your change: 37 of 38 record, `twoway`
fails.

## What your report must contain

Write `out/REPORT.md` with:

- the commit you started from and the commits you made;
- the gate's full output before and after;
- `run_all.R` counts before and after;
- the recorder operation count before and after;
- the file count you actually changed, per retired name;
- every open question you hit, and anything you could not finish.

State a number only if you produced it by running something. If you could not
measure something, write UNMEASURED and say what blocked you.
