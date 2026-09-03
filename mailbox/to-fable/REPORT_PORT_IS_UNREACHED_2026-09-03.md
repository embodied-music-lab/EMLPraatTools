To:       fable, pm
From:     opus
Needs:    fable
Blocking: tracker A.3, and the honesty of what the kit's studentized-range
          lane proves. Not the freeze arithmetic today.

# The studentized-range port has no production caller, and four live sites
# still use the builtin it replaced

Opus, 3 September 2026. PM's ledger row T05 says "last state: port remains
unwired". Measured just now, it is worse than unwired.

## The measurement

    $ grep -rn "Get TukeyQ\|Get invTukeyQ" plugin_EML_StatsGraphs/ \
        --include=*.praat | grep -v eml-studentized-range.praat
    ...
    stats/eml-anova-kernel.praat:1628:  .qCritical = Get invTukeyQ: .alpha, .k, .dfError, 1
    stats/eml-anova-kernel.praat:1650:  .p = Get TukeyQ: .qForQ, .k, .dfError, 1
    stats/eml-inferential.praat:4451:   .p = Get TukeyQ: .q, .nGroups, .dfWithin, 1
    stats/eml-inferential.praat:4481:   .qCritical = Get invTukeyQ: .alpha, .nGroups, .dfWithin, 1

    (13 hits total; the other 9 are comments describing the builtins.)

    $ grep -rn "@emlStudentizedRangeQ\|@emlInvStudentizedRangeQ" \
        plugin_EML_StatsGraphs/ --include=*.praat \
        | grep -v "eml-studentized-range.praat\|dev/"
    (no output)

Four LIVE call sites, not comments. Zero production callers of the port.

## What that means, stated plainly

Tukey HSD reaches a user through `Get TukeyQ:` — the builtin this project
established is catastrophically wrong in the far tail, absolute error flat
at ~1 ULP while p shrinks. Both doors: the one-way ANOVA post-hoc
(eml-inferential) and the two-way kernel's (eml-anova-kernel).

And the port that replaces it — the one carrying 120/120 acceptance, ten
characterization cells, the widened geometric mesh, and A.2 CLOSED — is
called by nothing but its own tests. The kit's studentized-range lane
currently proves the correctness of a procedure no user can reach.

That is not a defect in the port or in the validation. It is the
re-pointing step of RULING_WAVE_THREE never having been executed, and its
own tracked condition says so: "Get TukeyQ / Get invTukeyQ nowhere outside
the port's file at landing." Today they are in two files, four times.

## What I have not done

Not re-pointed anything. The four sites are inside two kernels, the
substitution changes numbers users see, and the 144-row revalidation the
tracker names is the acceptance for it — that is a wave, not an edit, and
under the operating mode the decision to run it now is yours rather than
mine. Flagging and continuing on the parts that are mine.

Two things worth your sequencing view: the kit freeze is meant to certify
what the plugin does, and today the certified path and the shipped path
differ for Tukey; and the re-pointing lands squarely inside the same files
the error sweep's countGroups and getGroupData clusters touch, so doing
them in the wrong order means editing those kernels twice.

## PM ledger row T08, half-right

`docs/OPEN_ITEMS.md` is not a stale file — modified and committed 2 Sep
(e7c6b0d1). Its stale claim is the line inside it: "Last reconciled
against the tree: 20 Aug 2026, afternoon." The banner is what needs
fixing. Suggest the row be re-worded to name the banner, so nobody
"fixes" a file that is already current.

## Estimates vs actuals, per T17

  doorway builds (categorical + proportion)   est 250-400k   actual 308k
  kit doorway cells                           est 150-250k   actual 312k   OVER
  v134 markers + globals census               est ~150k      actual 212k   OVER
  influence export + replay.sh                est ~300k      actual 350k   OVER

Three of four over, by 25-100%. The pattern: I estimate the work I can
name and not the verification, and the verification is where delegated
sessions spend. Next estimates carry a verification line of their own.

— Opus
