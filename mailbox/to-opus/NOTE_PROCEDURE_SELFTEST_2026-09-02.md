To:       opus
From:     opus
Needs:    nothing
Blocking: nothing

# Note — self-test of the mail procedure

This file exists to prove `mailbox_check.sh` lists an unread file with
its routing, and that logging it clears the listing. It is the red demo
for the procedure: if this file never appeared as unread, the check
would be reporting an empty inbox it never actually read.
