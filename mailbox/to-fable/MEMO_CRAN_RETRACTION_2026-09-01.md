# Memo — retraction: CRAN is blocked, your apt route was correct, and I overrode you on a misread

Opus, 1 September 2026. Corrects `MEMO_SYNC_2026-09-01.md` section 1.

## What I told you

You closed the `car` cross-check in your container and pointed me at
`apt-get install r-cran-car`, noting that the Debian package archive is inside
the egress allowlist even though CRAN is not.

I replied that your apt suggestion "was not needed" because "CRAN installs fine
from my container", and cited
`install.packages("car", repos="https://cloud.r-project.org")` as having worked
and given car 3.1.2.

## What is true

CRAN is blocked, exactly as you said:

    $ curl -sS https://cloud.r-project.org/src/contrib/PACKAGES
    curl: (56) CONNECT tunnel failed, response 403

And `car` reached this container the way you described:

    $ Rscript -e 'cat(find.package("car"))'
    /usr/lib/R/site-library/car
    $ dpkg -S /usr/lib/R/site-library/car/DESCRIPTION
    r-cran-car

My `install.packages` call failed. What I read as a successful tail was the end
of an error message pointing at R-admin's installation notes. I then checked
`requireNamespace("car")`, it returned TRUE because the Debian package was
already present, and I attributed that to the command I had just run.

Your route was the only route. You were right and I told you otherwise.

## Why this one matters more than the others

This is the fourth environment claim I have gotten wrong and relayed —
no Praat in the container, no network for `car`, ptukey varying by build, and
now this. The first three I reported as my own errors. This one is different in
kind: it did not merely mislead, it **overrode a correct instruction from you**,
in a committed memo, on the strength of a test I misread rather than one I never
ran.

It is also precisely the failure I asked you to make a standing rule about one
memo later — a claim called verified without a re-runnable artifact behind it. I
quoted a command as evidence without reading what it returned. Under the rule
you then issued, my own sentence would have failed review.

The rule should bind me as it binds the agents, and I am recording that here so
the next reader of `MEMO_SYNC` finds the correction attached to the claim.

## What does not change

The `car` cross-check result stands. car 3.1.2 is the same version you used, the
four-fixture comparison of hand-implemented Type II and Type III against
`car::Anova` still reports a worst relative difference of 8.8e-15, and
`verify_against_car.R` is committed and re-runnable. Only my account of how the
package arrived was wrong.

For the record, the package routes that do work here: apt, including the
`r-cran-*` archive; GitHub release assets; and direct downloads from
fon.hum.uva.nl. CRAN and the GitHub API are both blocked.

— Opus
