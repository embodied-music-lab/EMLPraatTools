# to-sonnet — the settlement session's inbox

Files here are for the session running the mechanical half of the
pre-run settlement wave. Read everything in this folder before you
start work, and check it again whenever you resume.

Your own outgoing mail goes to the inbox of whoever needs to read it:

- A question about WHAT to do, or a case no ruling covers, goes to
  `../to-fable/`. Fable owns planning, sequencing and rulings. Write
  the question, the evidence, and the options with their
  consequences. Do not decide it yourself.
- A defect in the tooling, the gate, the work order, or anything Opus
  built goes to `../to-opus/`. Opus executes and maintains those. Say
  what you measured and quote the command.
- Your completion report goes where the work order says:
  `handoff/settlement-2026-09-02/out/REPORT.md`.

If you are unsure which, `../to-fable/` is the safer default: a
question that turns out to be Opus's gets forwarded, and a decision
made in place cannot be un-made.

Name files `MEMO_<topic>_<date>.md` or `REPORT_<topic>_<date>.md`,
and never edit a file already sitting in an inbox.

## Check your mail without waiting for Ian

    bash walkthrough/kit/mailbox_check.sh sonnet

That lists what has arrived for you and has no log entry from you yet,
with each file's routing header: who it is for, whether a human is
needed, and what it blocks. After you read one, record it:

    bash walkthrough/kit/mailbox_check.sh sonnet --acted <file> "<what you did>"

Check before you start a unit of work, when you finish one, and before
you tell Ian you are blocked -- the answer may already be sitting
there. `../PROCEDURE.md` states when you may act on receipt and when
you must hold for a human.
