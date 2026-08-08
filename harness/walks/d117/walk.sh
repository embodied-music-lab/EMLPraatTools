#!/bin/bash
# ============================================================================
# D117 walk driver — one error-return site per invocation
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#   I=<instance> harness/walks/d117/walk.sh <site>
#
# Each site: navigate to the page, set every column field to something the
# COLUMN GUESS would not have chosen, trigger the error, dismiss it with Back,
# and screenshot the page it returns. Three shots per site into
# evidence/walks/d117/<site>_{before,error,after}.png.
#
# Set PLUGIN_SRC to a tree holding the pre-fix wizard to capture the
# differential; default is the working tree.
#
# The sites are the nine `@emlErrorDialog ... "wizard"` calls whose Back path
# re-enters a page carrying column optionmenus.
# ============================================================================
set -u
SITE=${1:?site}
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"
TAG=${TAG:-$SITE}

nav_goal () { popt 1 "$1"; pbtn 3 3; }              # Q1_GOAL   (3 buttons)
nav      () { popt 1 "$1"; pbtn 4 4; }              # any later one-menu page

case "$SITE" in

  # ── :761 two-factor, Factor 1 = Factor 2 ─────────────────────────────────
  # ── :785 two-factor, analysis error (data column holds no numbers) ───────
  s761_twofactor_samecol|s785_twofactor_analysiserr)
    launch "$HERE/tbl_2factor.praat"
    nav_goal 1                  # Compare groups or conditions
    nav 1                       # independent
    nav 3                       # two-factor design
    # menus: 1 Data column, 2 Factor 1, 3 Factor 2
    if [ "$SITE" = s761_twofactor_samecol ]; then
        popt 1 4; popt 2 3; popt 3 3      # SPL_dB, style, style
    else
        popt 1 1; popt 2 3; popt 3 2      # singer(text), style, sex
    fi
    shot "${TAG}_before"
    pbtn 4 4 4                  # Run
    shot "${TAG}_error"
    pbtn 2 2 4                  # Back
    shot "${TAG}_after"
    ;;

  # ── :870 paired columns, Column 1 = Column 2 ─────────────────────────────
  s870_paired_samecol)
    launch "$HERE/tbl_reg.praat"
    nav_goal 1
    nav 2                       # repeated (paired)
    nav 1                       # two conditions
    # menus: 1 Column 1, 2 Column 2
    popt 1 4; popt 2 4      # jitter_pct twice
    shot "${TAG}_before"
    pbtn 4 4 4
    shot "${TAG}_error"
    pbtn 2 2 4
    shot "${TAG}_after"
    ;;

  # ── :1287 regression columns, Predictor = Response ───────────────────────
  # ── :1307 regression columns, analysis error ─────────────────────────────
  s1287_regression_samecol|s1307_regression_analysiserr)
    launch "$HERE/tbl_reg.praat"
    nav_goal 2                  # Examine a relationship
    nav 2                       # Regression
    # menus: 1 Predictor, 2 Response
    if [ "$SITE" = s1287_regression_samecol ]; then
        popt 1 2; popt 2 2  # SPL_dB twice
    else
        popt 1 1; popt 2 3  # singer(text) predicts vibrato_rate_Hz
    fi
    shot "${TAG}_before"
    pbtn 4 4 4
    shot "${TAG}_error"
    pbtn 2 2 4
    shot "${TAG}_after"
    ;;

  # ── :1375 correlation columns, Column 1 = Column 2 ───────────────────────
  s1375_correlation_samecol)
    launch "$HERE/tbl_reg.praat"
    nav_goal 2
    nav 1                       # Correlation
    # menus: 1 Column 1, 2 Column 2
    popt 1 4; popt 2 4      # jitter_pct twice
    shot "${TAG}_before"
    pbtn 4 4 4
    shot "${TAG}_error"
    pbtn 2 2 4
    shot "${TAG}_after"
    ;;

  # ── :1549 describe one column, analysis error ────────────────────────────
  s1549_describe_analysiserr)
    launch "$HERE/tbl_reg.praat"
    nav_goal 3                  # Describe or summarize
    nav 1                       # single variable
    # menus: 1 Data column
    popt 1 1                  # singer (text)
    shot "${TAG}_before"
    pbtn 4 4 4
    shot "${TAG}_error"
    pbtn 2 2 4
    shot "${TAG}_after"
    ;;

  # ── :1725 predict columns, Predictor = Outcome ───────────────────────────
  # ── :1745 predict columns, analysis error ────────────────────────────────
  s1725_predict_samecol|s1745_predict_analysiserr)
    launch "$HERE/tbl_reg.praat"
    nav_goal 4                  # Predict from one or more variables
    # menus: 1 Predictor, 2 Outcome
    if [ "$SITE" = s1725_predict_samecol ]; then
        popt 1 2; popt 2 2
    else
        popt 1 1; popt 2 3
    fi
    shot "${TAG}_before"
    pbtn 4 4 4
    shot "${TAG}_error"
    pbtn 2 2 4
    shot "${TAG}_after"
    ;;

  # ── A2A / A2B: NOT among the nine. These two pages already preserved
  # their columns correctly; D117 only routed them through @wizardColIdx so
  # the file holds one idiom instead of two hand-written copies of the loop.
  # Driven to confirm the conversion changed nothing a user can see.
  a2a_twogroups_regression)
    launch "$HERE/tbl_groups.praat"
    nav_goal 1
    nav 1                       # independent
    nav 1                       # two groups
    # menus: 1 Data column, 2 Group column. voice_type holds THREE groups,
    # so the "Expected 2 groups" guard fires.
    popt 1 4; popt 2 2          # vibrato_rate_Hz by voice_type
    shot "${TAG}_before"
    pbtn 4 4 4                  # Continue
    shot "${TAG}_error"
    pbtn 2 2 4                  # Back
    shot "${TAG}_after"
    ;;

  a2b_kgroups_regression)
    launch "$HERE/tbl_2factor.praat"
    nav_goal 1
    nav 1
    nav 2                       # three or more groups
    # sex holds TWO groups, so the "Only 2 groups" guard fires.
    popt 1 1; popt 2 2          # singer by sex
    shot "${TAG}_before"
    pbtn 4 4 4
    shot "${TAG}_error"
    pbtn 2 2 4
    shot "${TAG}_after"
    ;;

  *) echo "walk.sh: unknown site $SITE" >&2; exit 2 ;;
esac

# RUNAFTER=1 — the defect proper. Press Run on the returned page WITHOUT
# touching a field, then read the Info window: it must report the analysis the
# user configured, not the column guess. Pre-fix this is where the wizard
# silently runs a different model and prints a second, different Analysis Plan
# beside the user's own.
if [ "${RUNAFTER:-0}" = 1 ]; then
    pbtn 4 4 5
    shot "${TAG}_runagain"
    case "$(ptitle)" in
        *"Analysis complete"*) pbtn 1 4 3 ;;   # Done — it ran something
        *)                     pbtn 1 2 3 ;;   # Quit — it refused again
    esac
    sleep 2
    infodump "$OUT/${TAG}_info.txt"
    echo "--- Analysis Plans reported ---"
    grep -E "Column 1:|Column 2:|Data column:|Group column:" "$OUT/${TAG}_info.txt"
fi

echo "$SITE done — window now: $(ptitle)"
