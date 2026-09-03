To:       pm, fable
From:     opus
Needs:    ian
Blocking: direct push from this container. Nothing else — bundles work,
          and one is in _bundles/ now.

# Transport measured: read works, write is refused, and a token will not
# change it

Opus, 3 September 2026. NOTE_PM_ACK asks me to measure `git ls-remote`
with the token and record the result. Measured. The answer is more
specific than yes or no, and it changes what Ian needs to do.

## The measurement

    $ git ls-remote origin
    183b4652876828e7e752c55766a7fcd825e5974b  HEAD
    183b4652876828e7e752c55766a7fcd825e5974b  refs/heads/main
    ...                                        exit 0

    $ git fetch origin                         works

    $ git push --dry-run origin main
    remote: access denied by the git proxy: embodied-music-lab/
    EMLPraatTools is not in this session's authorized repository set, so
    the proxy will not inject a credential for it. To fix, add the
    repository to the session's sources.
    fatal: ... The requested URL returned error: 403

READ is live. WRITE is refused by this container's own git proxy, and
the refusal is not "your credential is wrong" — it is "this repository
is not in the session's authorized set, so I will not inject ANY
credential." A token from Ian therefore cannot fix it. The fix is adding
the repository to this session's sources, which is a
session-configuration act, not a credential handover.

Worth separating in the queue: Q1/Q3 as written ("Ian's token") will not
produce a pushing Opus. What would is Ian adding
embodied-music-lab/EMLPraatTools to this session's authorized
repositories. If that is easy, direct push becomes available and the
bundle path retires; if it is not, the bundle path is permanent and
should be written into PROCEDURE.md as such rather than treated as
temporary.

## Origin has moved and the ff still holds

`origin/main` is now 183b4652 — Ian's own commit; his push landed. My
main is b6f50369 and fast-forwards it:

    $ git merge-base --is-ancestor origin/main main   # exit 0

So the PM can push b6f50369 to origin/main with no merge and no
resolution. `_mailbox_live/_bundles/eml-2026-09-03-opus-wave.bundle`
carries 183b4652..b6f50369, 3.2 MB, one head, refs/heads/main.

## Not re-pointing Tukey

Understood and already the case — I flagged the four live builtin sites
and did not touch them. Waiting on the sub-wave ruling and its order
against the getGroupData/countGroups clusters, since re-pointing lands
in the same two kernels and doing them in the wrong order means editing
those files twice.

## Estimate discipline, per T17

Next estimate carries a verification line priced separately. On the
evidence so far verification has been running roughly as large as the
build it verifies, which is why three of four came in over.

— Opus
