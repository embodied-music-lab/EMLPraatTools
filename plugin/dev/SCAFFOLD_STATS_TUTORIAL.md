# EML Stats Interactive Tutorial — Pedagogical Architecture
# SCAFFOLD DOCUMENT
# Date: 31 March 2026
# Status: Design review — awaiting APPROVE

---

## 0. Design Philosophy

**Audience:** True novices. People who say "I have some data" and don't
know what to do next. They may be voice teachers, performing arts
students, clinicians who've always had someone else do their stats. They
know their domain (voices, singing, speech) but not data analysis.

**Medium:** Praat Demo window — interactive canvas with click/key
navigation, live drawing, and the ability to create Praat objects the
user can see and inspect.

**Pedagogical principle:** Questions before answers, pictures before
numbers, intuition before formulas. Every concept is introduced through
a concrete voice-science scenario the audience already understands.
Jargon is introduced AFTER the concept clicks, never before.

**Audio integration:** The tutorial creates real Sound objects, extracts
real acoustic measurements, and builds Tables from them. The user sees
the Objects list populate. This bridges the tutorial to their own work —
when the tutorial ends, they have objects they can inspect and manipulate.

**Navigation model:** Linear progression with a home screen for module
jumping. Arrow keys or click to advance. ESC exits cleanly from any
page. Each module has a title card, content pages, and a summary card.

**Visual language:** Consistent across all modules:
- Dark blue-gray background (not white — Demo window should feel
  different from the Picture window)
- Title area at top (18pt, white)
- Content area in the middle (12pt, cream/light)
- Navigation hint at bottom ("→ or click to continue | ← to go back")
- Highlighted terms in a distinct color when first introduced
- Drawings in a defined sub-viewport within the content area
- Smooth transitions between pages (selective repaint, not full erase)

---

## 1. Module Map

```
HOME SCREEN
 │
 ├── Part 1: YOUR DATA
 │    ├── Module 1: What Is Data?
 │    ├── Module 2: Looking at Your Data (Shape)
 │    └── Module 3: Describing Your Data (Numbers)
 │
 ├── Part 2: ASKING QUESTIONS
 │    ├── Module 4: Are These Groups Different?
 │    ├── Module 5: Before and After
 │    ├── Module 6: More Than Two Groups
 │    └── Module 7: Do These Move Together?
 │
 ├── Part 3: THE FULL PICTURE
 │    ├── Module 8: Change Over Time
 │    ├── Module 9: Choosing the Right Test
 │    └── Module 10: Graph Gallery
 │
 └── EXIT (objects remain for user to explore)
```

**Estimated total runtime:** 25–35 minutes (self-paced, all modules)
**Minimum viable path:** Modules 1–5 + 9 (~15 minutes)

---

## 2. Module Specifications

### MODULE 1: "What Is Data?"

**Goal:** User understands that data = organized observations in rows
and columns, and that Praat Tables hold data.

**Audio integration:** Creates 6 synthetic vowels (/a/) with different
F0 values (3 "before therapy," 3 "after therapy"). User hears each
one briefly (`asynchronous Play`). Script extracts mean F0 from each
using `To Pitch` → `Get mean`. Values populate a Table row by row,
visible in the Demo window AND in Praat's Objects list.

**Page sequence:**

1. **Title card:** "What Is Data?"

2. **The scenario:** "Imagine you're a voice therapist. Six clients
   come to your clinic. Three haven't started therapy. Three have
   finished a course of therapy. You record each of them saying 'ah'
   and measure their pitch."
   [Six small speaker icons arranged in two groups]

3. **Hearing the data:** "Let's listen to each recording."
   [Plays each synthetic vowel briefly. Shows waveform snippet in a
   small drawing area. Labels: "Client 1: before therapy" etc.]
   User clicks/arrows to hear each one.

4. **Measuring:** "Praat measured the pitch of each recording. Here
   are the numbers."
   [Numbers appear next to each speaker icon: e.g., 185 Hz, 210 Hz...]

5. **Organizing:** "To work with these numbers, we need to organize
   them. Every person gets their own ROW. Every measurement gets its
   own COLUMN."
   [Animated table construction: grid lines appear, then row labels,
   then column headers ("client", "group", "pitch_Hz"), then values
   fill in cell by cell]

6. **The Praat Table:** "This organized grid is called a TABLE. Praat
   just created one — you can see it in the Objects list on the left."
   [Arrow or highlight pointing to Objects list. The Table object
   'tutorialData' is now there.]

7. **Key ideas recap:**
   - Each ROW = one observation (one person, one recording)
   - Each COLUMN = one type of information
   - A TABLE organizes observations so we can analyze them
   [Visual: labeled table with row/column annotations]

**Objects created:** `tutorialData` (Table, 6 rows: client, group,
pitch_Hz). Six Sound objects removed after measurement (or kept — 
design choice; leaning toward remove to avoid clutter).

**Praat concepts introduced:** Table, row, column, Objects list.

---

### MODULE 2: "Looking at Your Data"

**Goal:** User understands that before doing any test, you should
LOOK at your data. Introduces distribution shape through histograms
and dot plots.

**Audio integration:** Extends the Table from Module 1 to 30 rows
(15 before, 15 after) using synthetic vowels with randomized F0.
This happens quickly — the user sees a progress indicator, not
individual playback. The point is "we recorded 30 people" without
making them listen to 30 vowels.

**Page sequence:**

1. **Title card:** "Looking at Your Data"

2. **More data:** "Six clients wasn't very many. Let's imagine we
   recorded 30 — 15 before therapy and 15 after."
   [Table from Module 1 grows — rows appear, count ticks up]
   [tutorialData Table now has 30 rows]

3. **The dot plot:** "Here's the simplest picture of data. Each dot
   is one person's pitch."
   [Y-axis = pitch, dots scattered vertically at x=1, all same color.
   Dots appear one by one, dropping into place.]

4. **Where's the middle?** "Where do most of the values cluster?"
   [User clicks where they think the middle is. A horizontal line
   appears at the median. Label: "This is the MEDIAN — the middle
   value. Half the dots are above, half below."]
   [Then: mean line appears in different color. "This is the MEAN —
   the mathematical average. It's pulled toward extreme values."]

5. **How spread out?** "Are the dots tightly packed or spread wide?"
   [Box appears showing IQR. "The middle 50% of values fall in this
   box. This spread is called the INTERQUARTILE RANGE (IQR)."]
   [Then: whiskers extend. "The full spread from lowest to highest
   is the RANGE."]

6. **The histogram:** "Another way to see the shape: stack up how
   many values fall in each bin."
   [Dot plot morphs into histogram — dots slide horizontally into
   bins. This is the key animation: the user sees that a histogram
   IS a count of dots in intervals.]
   
7. **Shape vocabulary:** "Distributions have shapes."
   [Three small histograms side by side:]
   - Symmetric (bell-shaped): "Most values near the middle"
   - Right-skewed: "A tail stretching toward high values"
   - Left-skewed: "A tail stretching toward low values"
   "Our data's shape tells us which statistical tools are
   appropriate."

8. **Key ideas recap:**
   - Always LOOK at data before testing
   - **Histogram** → shape of the distribution
   - **Dot plot** → individual values and spread
   - Center (mean, median) and spread (range, IQR) are the first
     things to notice

**Graph types introduced:** Histogram (type 10), dot plot concept
(precursor to violin/box).

**Stats concepts introduced:** Median, mean, range, IQR, distribution
shape, skewness (intuitive, not formula).

---

### MODULE 3: "Describing Your Data"

**Goal:** Systematic tour of all descriptive statistics. User
understands what each number tells them and when it matters.

**Data:** Uses the 30-row tutorialData from Module 2.

**Page sequence:**

1. **Title card:** "Describing Your Data — The Numbers Behind the
   Picture"

2. **Center: Mean vs. Median.**
   [Dot plot with both lines. Add an extreme outlier (e.g., 450 Hz).
   Mean jumps. Median barely moves.]
   "The MEAN is sensitive to outliers. The MEDIAN is resistant.
   When they're very different, your data is probably skewed."
   [Remove outlier. Both settle back together.]

3. **Spread: SD, Variance, SEM, IQR, Range, MAD.**
   [Visual: same dot plot. Each spread measure drawn as a different
   visual annotation:]
   - **Range** (min to max): bracket spanning all dots. "Simplest,
     but one outlier wrecks it."
   - **IQR** (Q1 to Q3): shaded box. "Middle 50%. Robust like
     the median."
   - **SD** (standard deviation): colored band around the mean.
     "The typical distance from the mean. ~68% of values fall
     within ±1 SD of the mean in a bell-shaped distribution."
   - **Variance**: "SD squared. Useful in formulas but hard to
     interpret directly because the units are squared (Hz²)."
   - **SEM** (standard error): narrower band. "How precisely we
     know the mean. Gets smaller with more data. NOT the same as
     SD — SD describes the data, SEM describes the estimate."
   - **MAD** (median absolute deviation): "Like SD but for the
     median. Robust to outliers."
   [Each measure appears and is explained, then fades to
   background as the next appears.]

4. **Quartiles deep dive.**
   [Sorted dot plot. Lines at Q1, Q2 (median), Q3.]
   "Sort all values from lowest to highest. Q1 = 25th percentile,
   Q2 = 50th (the median), Q3 = 75th. The IQR = Q3 minus Q1."
   [Box plot appears beside the dot plot — user sees the connection
   between raw dots and the box plot summary.]

5. **Shape: Skewness and Kurtosis.**
   [Three histograms with skewness values:]
   - Symmetric: skewness ≈ 0
   - Right skew: skewness > 0 ("tail goes right, skew is positive")
   - Left skew: skewness < 0
   "Skewness tells you about asymmetry."
   
   [Three histograms with kurtosis values:]
   - Normal: kurtosis ≈ 0
   - Heavy tails: kurtosis > 0 ("more extreme values than expected")
   - Light tails: kurtosis < 0 ("fewer extreme values")
   "Kurtosis tells you about tail weight — how likely extreme
   values are."

6. **Confidence Interval.**
   [Dot plot with mean marked. CI bracket around it.]
   "If we recorded 30 MORE people from the same population, their
   mean would probably land inside this bracket. The 95% CI says:
   'We're 95% confident the true population mean is in this range.'
   More data → narrower CI → more precise estimate."

7. **The box plot — all in one picture.**
   [Builds a box plot piece by piece, labeling each component:]
   - Median line
   - Box (Q1–Q3 = IQR)
   - Whiskers (1.5 × IQR from box edges, or data extent)
   - Outlier dots (beyond whiskers)
   "The BOX PLOT summarizes center, spread, quartiles, and outliers
   in one compact picture."

8. **The violin plot — shape + summary.**
   [Box plot morphs into violin plot — KDE curves grow out from the
   box sides.]
   "The VIOLIN PLOT adds the distribution shape. The wider the
   violin, the more values at that level. It combines the histogram's
   shape information with the box plot's summary statistics."

9. **When to use which graph:**
   | Graph | Shows | Best for |
   |-------|-------|----------|
   | Histogram | Distribution shape, bin counts | One variable, seeing shape |
   | Dot plot | Individual values | Small samples, seeing every point |
   | Box plot | Median, quartiles, outliers | Comparing groups compactly |
   | Violin | Shape + quartiles | Comparing groups with shape |
   | Bar chart | Means + error bars | Familiar summary (but hides shape) |

10. **Key ideas recap:**
    Complete list of descriptive stats with one-line plain-language
    definitions.

**Graph types introduced:** Box plot (type 9), violin plot (type 7),
bar chart (type 6) — shown in context, building from simpler to more
informative.

**Stats concepts introduced:** SD, variance, SEM, MAD, quartiles,
skewness, kurtosis, CI, trimmed mean (brief mention). All descriptive
outputs from @emlDescribe.

---

### MODULE 4: "Are These Groups Different?"

**Goal:** User understands the logic of hypothesis testing — signal
vs. noise, p-values, effect sizes — through the two-group comparison.

**Data:** The tutorialData Table, now using the "group" column
(before/after therapy) to split the data.

**Page sequence:**

1. **Title card:** "Are These Groups Different?"

2. **Two groups, side by side.**
   [Two dot clusters or two violins, color-coded: blue = before,
   orange = after.]
   "Here are our two groups. The 'after therapy' group looks like
   it has higher pitch on average. But is that a REAL difference, or
   could it be just luck — random variation?"

3. **The core question.**
   [Visual: two overlapping distributions. Arrow pointing to the
   gap between means. Arrow pointing to the spread within each group.]
   "A statistical test compares SIGNAL (the gap between groups) to
   NOISE (the spread within groups). If the signal is large relative
   to the noise, we have evidence of a real difference."

4. **The t-test — intuition.**
   [Animated: t = (gap between means) / (pooled variability).
   Show the fraction visually — numerator bar and denominator bar.
   As t gets larger, the fraction gets larger.]
   "The T-TEST computes a ratio: how many 'units of noise' apart are
   the two group means? A t-value of 3 means the means are 3 noise-
   units apart — that's a big gap."

5. **The p-value.**
   [Sampling distribution visualization: bell curve of "what t would
   look like if there were NO real difference." Our observed t marked
   with an arrow. Shaded tail = p-value.]
   "The P-VALUE answers: 'If there were truly no difference, how
   often would I see a gap this large just by chance?'
   - p = 0.03 means 3 times out of 100 — pretty unlikely by chance
   - p = 0.50 means 50 times out of 100 — totally plausible by chance
   Convention: p < 0.05 is 'statistically significant.'"
   "But p does NOT tell you how big the difference is."

6. **Effect size.**
   [Same two distributions. Overlap visualization — Cohen's d
   shifts one distribution relative to the other.]
   "COHEN'S D tells you the SIZE of the difference in standard
   deviation units.
   - d = 0.2: small (distributions almost fully overlap)
   - d = 0.5: medium (moderate overlap)
   - d = 0.8: large (clearly separated)
   The p-value tells you IF there's a difference. The effect size
   tells you HOW BIG."

7. **Parametric vs. nonparametric.**
   [Two histograms: one bell-shaped, one clearly skewed.]
   "The t-test assumes your data is roughly bell-shaped. When it's
   not — when it's heavily skewed or has outliers — the
   MANN-WHITNEY U TEST is a safer alternative. It compares ranks
   (ordering) instead of means."
   [Same two groups shown with rank ordering. Visual of the U
   computation as counting "how many times a value from Group A
   beats a value from Group B."]

8. **What EML Tools does for you.**
   [Side-by-side: violin plot with annotation brackets showing
   t-test result, p-value, and Cohen's d — the actual output
   the plugin produces.]
   "EML Tools runs both the parametric and nonparametric test,
   reports effect sizes, and draws the picture — all in one click."

9. **Key ideas recap:**
   - t-test: signal / noise ratio for two groups
   - p-value: probability of seeing this result if no real difference
   - Effect size (Cohen's d): how big the difference is
   - Parametric (t-test) vs. nonparametric (Mann-Whitney U)
   - Always report BOTH p-value and effect size

**Graph types featured:** Violin plot (type 7), box plot (type 9),
bar chart (type 6) — all shown as ways to display two-group data.

**Stats procedures showcased:** @emlTTest, @emlMannWhitneyU,
@emlCohenD, @emlRankBiserialR, @emlFormatP, @emlFormatEffectLabel.

---

### MODULE 5: "Before and After"

**Goal:** User understands paired/repeated-measures data — same
subjects measured twice — and why it needs different tests.

**Audio integration:** Creates paired synthetic vowels — same
"speaker" with slightly different F0 before and after. Playing
both shows the subtle within-subject shift.

**Data:** Extends tutorialData with a "subject" column. Same 15
people appear in both the before and after groups.

**Page sequence:**

1. **Title card:** "Before and After — When the Same People Are
   Measured Twice"

2. **Independent vs. paired.**
   [Left: two separate groups of stick figures (different people).
   Right: one group with arrows connecting before→after (same people).]
   "In Module 4, we compared different people. But often in voice
   research, you measure the SAME people before and after an
   intervention. This is PAIRED data — each 'before' measurement
   has a partner 'after' measurement from the same person."

3. **Why pairing matters.**
   [Connected dot plot: lines connecting pre→post for each subject.
   Some go up, some go down, most go up.]
   "When we pair the data, we can track each person's change. The
   test focuses on the CHANGES, not the raw values. This removes
   person-to-person variability and makes the test more powerful."

4. **The paired t-test.**
   [Visual: difference scores computed. Each connecting line becomes
   a single difference value on a new axis. "Did the difference
   scores come from a population with mean = 0?"]
   "The PAIRED T-TEST is just a one-sample t-test on the
   differences. If the differences are consistently positive (or
   negative), the intervention probably worked."

5. **Wilcoxon signed-rank.**
   [Same paired data but with a skewed difference distribution.]
   "When the differences aren't bell-shaped, the WILCOXON
   SIGNED-RANK TEST is the nonparametric alternative. It ranks
   the absolute differences and compares positive vs. negative
   ranks."

6. **The spaghetti plot.**
   [Lines connecting conditions for each subject, colored by group
   or individual.]
   "The SPAGHETTI PLOT shows every subject's trajectory. When most
   lines go the same direction, the effect is consistent. When
   lines cross, the effect is inconsistent or absent."

7. **Key ideas recap:**
   - Paired data: same subjects measured multiple times
   - Connected dot plot: visualize individual changes
   - Spaghetti plot: multiple conditions per subject
   - Paired t-test (parametric) vs. Wilcoxon signed-rank
     (nonparametric)
   - Effect size: matched-pairs r

**Graph types featured:** Spaghetti plot (type 14), connected dot
plot concept (manual drawing, precursor to spaghetti).

**Stats procedures showcased:** @emlTTestPaired (if exists, else
explain conceptually), @emlWilcoxonSignedRank, @emlMatchedPairsR.

---

### MODULE 6: "More Than Two Groups"

**Goal:** User understands why comparing three or more groups needs
different tools (ANOVA, Kruskal-Wallis) and what post-hoc tests do.

**Data:** Extends tutorialData to three groups (e.g., "no therapy,"
"6 weeks therapy," "12 weeks therapy") or creates a new Table.

**Page sequence:**

1. **Title card:** "More Than Two Groups"

2. **The multiple comparisons problem.**
   [Three groups. Arrows showing all pairwise comparisons: A vs B,
   A vs C, B vs C.]
   "With two groups, we ran one test. With three groups, we'd need
   THREE comparisons. With four groups, SIX. Each test has a 5%
   chance of a false positive. Run enough tests and you'll find
   'significant' results that aren't real."
   [Visual: stacking probabilities. "3 tests × 5% each ≈ 14%
   chance of at least one false alarm."]

3. **ANOVA — the omnibus test.**
   [Three group violin plots. Visual: between-group variance
   (spread of group means) vs. within-group variance (spread
   within each group).]
   "ANOVA asks: 'Is there ANY difference among these groups?'
   It compares variation BETWEEN groups to variation WITHIN groups.
   Like the t-test's signal/noise, but for multiple groups at once."
   [F-ratio visualization: between / within.]

4. **Kruskal-Wallis — the nonparametric version.**
   "Just as Mann-Whitney is the nonparametric version of the t-test,
   KRUSKAL-WALLIS is the nonparametric version of ANOVA. It works
   on ranks and doesn't assume bell-shaped data."

5. **Post-hoc tests: which pairs differ?**
   [ANOVA says "yes, there's a difference somewhere." But where?]
   "Post-hoc tests compare specific pairs WHILE controlling for
   the multiple comparisons problem."
   [Visual: comparison matrix — grid showing each pair with its
   adjusted p-value.]
   - **Tukey HSD:** Most common. Compares all pairs, controls for
     family-wise error.
   - **Dunn's test:** Post-hoc for Kruskal-Wallis (rank-based).
   [Show the annotation matrix as EML Graphs renders it.]

6. **p-value adjustment.**
   "Instead of special post-hoc tests, you can also run regular
   pairwise comparisons and ADJUST the p-values."
   - **Bonferroni:** Strictest — multiply p by number of tests.
     Very conservative.
   - **Holm:** Step-down — less conservative, still controls error.
   - **Benjamini-Hochberg:** Controls false discovery rate — most
     powerful, but tolerates some false positives.
   [Visual: same p-values shown with each adjustment method.
   Some cross the 0.05 line, some don't, depending on method.]

7. **Effect sizes for multiple groups.**
   - **Eta-squared (η²):** Proportion of total variance explained
     by group membership. Like R² for ANOVA.
   - **Epsilon-squared (ε²):** Analogous for Kruskal-Wallis.
   "These tell you how much of the variation in your data is
   explained by which group people belong to."

8. **Grouped plots.**
   [Grouped violin and grouped box plot examples.]
   "When you have TWO grouping factors (e.g., therapy type AND
   gender), GROUPED plots show them simultaneously."

9. **Key ideas recap:**
   - Multiple comparisons inflate false positives
   - ANOVA / Kruskal-Wallis: omnibus "is there ANY difference?"
   - Post-hoc tests (Tukey, Dunn's): which specific pairs?
   - p-adjustment methods: Bonferroni, Holm, BH
   - Grouped violin/box for factorial designs

**Graph types featured:** Violin plot (multiple groups), grouped
violin (type 11), grouped box plot (type 12), annotation matrix.

**Stats procedures showcased:** @emlOneWayAnova, @emlKruskalWallis,
@emlTukeyHSD, @emlDunnTest, @emlPairwiseT, @emlPairwiseWilcoxon,
@emlScheffe, @emlBonferroni, @emlHolm, @emlBenjaminiHochberg,
@emlEtaSquared, @emlEpsilonSquared.

---

### MODULE 7: "Do These Move Together?"

**Goal:** User understands correlation — positive, negative, none —
and the difference between correlation and causation.

**Audio integration:** Creates pairs of synthetic vowels varying in
F0 and intensity. "Speakers who talk at higher pitch also tend to
talk louder." User sees/hears the relationship.

**Data:** New paired columns in tutorialData (or new Table):
speaking_F0, singing_F0 (planted positive correlation).

**Page sequence:**

1. **Title card:** "Do These Move Together?"

2. **Scatter plot introduction.**
   [Points appear one by one on a scatter plot. X = speaking F0,
   Y = singing F0.]
   "Each dot is one person. Their speaking pitch is on the
   horizontal axis, their singing pitch is on the vertical axis.
   As speaking pitch goes up... does singing pitch go up too?"

3. **Positive, negative, none.**
   [Three scatter plots side by side, animated:]
   - Positive (r ≈ 0.8): cloud tilts up-right
   - Negative (r ≈ −0.7): cloud tilts down-right
   - None (r ≈ 0.0): circular cloud
   "The CORRELATION COEFFICIENT (r) measures the strength and
   direction of a linear relationship.
   r = +1: perfect positive, r = −1: perfect negative, r = 0: none."

4. **Pearson vs. Spearman.**
   [Left: linear relationship (Pearson works). Right: monotonic but
   curved relationship (Spearman handles it).]
   "PEARSON'S r measures LINEAR relationships — straight-line
   patterns. SPEARMAN'S ρ (rho) measures MONOTONIC relationships —
   'when one goes up, the other tends to go up' even if the pattern
   curves. Use Spearman when the relationship isn't straight or
   when you have outliers."

5. **The regression line.**
   [Regression line appears on the scatter plot. Residuals shown
   as vertical lines from each point to the line.]
   "The REGRESSION LINE is the best-fitting straight line through
   the cloud. It lets you predict one variable from the other —
   but only within the range of your data."

6. **Correlation ≠ causation.**
   [Classic example: ice cream sales and drownings both correlate
   with temperature. Visual showing hidden third variable.]
   "A strong correlation does NOT mean one thing CAUSES the other.
   People who speak at higher pitch may also sing at higher pitch —
   but that doesn't mean changing someone's speaking pitch will
   change their singing pitch. There could be a third factor
   (vocal fold anatomy, body size) driving both."

7. **Key ideas recap:**
   - Scatter plot: see relationships between two variables
   - Pearson r: linear relationships
   - Spearman ρ: monotonic relationships
   - r² = proportion of variance shared
   - Correlation ≠ causation

**Graph types featured:** Scatter plot (type 8) with regression line.

**Stats procedures showcased:** @emlPearsonCorrelation,
@emlSpearmanCorrelation.

---

### MODULE 8: "Change Over Time"

**Goal:** User understands time-series data, repeated measures across
multiple time points, and group-level trends with uncertainty.

**Data:** New Table: 10 subjects × 4 time points (weeks 0, 2, 4, 6)
× pitch measurement. Optional: two groups (treatment, control).

**Page sequence:**

1. **Title card:** "Change Over Time"

2. **Time series — one subject.**
   [Single line graph: x = week, y = pitch. Points connected.]
   "When you measure the same thing at multiple time points, you
   get a TIME SERIES. This shows one person's pitch over 6 weeks
   of therapy."

3. **Spaghetti plot — all subjects.**
   [Multiple overlaid lines, each a different subject. Some go up,
   some stay flat.]
   "Plotting everyone together shows the PATTERN. Are most people
   improving? Are some getting worse? The SPAGHETTI PLOT shows
   individual variability."

4. **Group averages with confidence.**
   [Spaghetti fades to background. Group mean line appears with
   CI band (shaded).]
   "The group average shows the TREND. The shaded band shows
   UNCERTAINTY — the wider the band, the less consistent the
   individual trajectories."
   [Time Series with CI graph type]

5. **Comparing groups over time.**
   [Two group lines (treatment, control) with CI bands.]
   "When bands don't overlap, the groups are likely different at
   that time point."

6. **Key ideas recap:**
   - Time series: measurements over time
   - Spaghetti plot: individual trajectories
   - Time series with CI: group trends with uncertainty
   - Repeated measures require paired/within-subject analysis

**Graph types featured:** Time series (type 5), spaghetti plot
(type 14), time series with CI (type 13).

---

### MODULE 9: "Choosing the Right Test"

**Goal:** User can navigate the decision tree from question →
data structure → appropriate test. This is the bridge to the wizard.

**Page sequence:**

1. **Title card:** "Choosing the Right Test — A Decision Guide"

2. **Start with the question, not the test.**
   "You don't pick a test from a menu. You answer three questions
   about YOUR situation, and the right test follows."

3. **Question 1: What are you trying to do?**
   [Interactive: user clicks one of three options]
   - "DESCRIBE one variable" → descriptive stats
   - "COMPARE groups" → go to Q2
   - "FIND A RELATIONSHIP between two variables" → correlation

4. **Question 2 (if Compare): How many groups?**
   - Two groups → go to Q3
   - Three or more → ANOVA / Kruskal-Wallis → post-hoc

5. **Question 3 (if Two groups): Same or different people?**
   - Different people → t-test / Mann-Whitney U
   - Same people (paired) → paired t-test / Wilcoxon signed-rank

6. **The parametric/nonparametric fork.**
   "At every branch, you have two versions:
   - PARAMETRIC: assumes roughly bell-shaped data. More powerful
     when the assumption holds.
   - NONPARAMETRIC: makes no shape assumption. Safer when data
     is skewed or small."

7. **Complete decision tree** (drawn as flowchart):

   ```
   What's your question?
   │
   ├── Describe → @emlDescribe + histogram/violin
   │
   ├── Compare groups
   │    ├── 2 groups
   │    │    ├── Independent → t-test / Mann-Whitney U
   │    │    └── Paired → paired t / Wilcoxon
   │    └── 3+ groups
   │         ├── Omnibus → ANOVA / Kruskal-Wallis
   │         └── Post-hoc → Tukey / Dunn's / pairwise
   │
   └── Relationship → Pearson r / Spearman ρ
   ```

8. **"This is exactly what the EML Wizard does."**
   "The EML Stats Wizard asks you these same questions and runs
   the right test automatically. You just completed the logic
   behind it."

9. **Key ideas recap:**
   - Start with your research question
   - Data structure (groups, pairing, sample size) determines the test
   - Parametric vs. nonparametric: check your data's shape
   - Effect sizes always, p-values with context

---

### MODULE 10: "Graph Gallery"

**Goal:** Comprehensive visual reference of all 14 graph types with
use-case mapping. Each graph shown with a brief explanation of what
it reveals, what data structure it needs, and which statistical
context it pairs with.

**Page sequence:**

1. **Title card:** "Graph Gallery — Every Picture Tells a Story"

2. **Acoustic graphs (from Praat objects):**
   [Each drawn in a sub-viewport with description]
   
   a. **Waveform** (from Sound)
      "The raw audio signal. Amplitude over time. Your starting
      point for any acoustic analysis."
   
   b. **Pitch Contour** (from Pitch)
      "Fundamental frequency over time. Shows intonation patterns,
      pitch range, and stability."
   
   c. **Spectrum** (from Spectrum)
      "Frequency content at a single moment. Shows harmonics,
      formants, noise."
   
   d. **LTAS — Long-Term Average Spectrum** (from Ltas)
      "Average frequency content over a longer stretch. Smooths out
      moment-to-moment variation to show overall spectral character."

3. **Distribution graphs (from Table, one variable):**
   
   e. **Histogram**
      "Shows the SHAPE of your data. How many values fall in each
      range? Use for: checking normality, seeing modes, identifying
      outliers."
      Pairs with: @emlDescribe, shape assessment
   
   f. **Violin Plot**
      "Shape + summary. The smooth outline shows distribution shape.
      The box inside shows median and quartiles."
      Pairs with: t-test, Mann-Whitney, group comparisons
   
   g. **Box Plot**
      "Compact summary: median, quartiles, whiskers, outliers.
      Best for comparing many groups at a glance."
      Pairs with: same as violin, ANOVA, Kruskal-Wallis

4. **Comparison graphs (from Table, groups):**
   
   h. **Bar Chart**
      "Shows group means with error bars (SE or SD). Familiar but
      hides distribution shape. Use when the audience expects bars."
      Pairs with: t-test, ANOVA, group means
   
   i. **Grouped Violin**
      "Two grouping factors shown simultaneously. Categories on
      x-axis, sub-groups as side-by-side violins."
      Pairs with: factorial designs, two-way interactions
   
   j. **Grouped Box Plot**
      "Same as grouped violin but box plot style. More compact,
      less shape information."
      Pairs with: same as grouped violin

5. **Relationship graphs (from Table, two variables):**
   
   k. **Scatter Plot**
      "Each dot is one observation plotted on two axes. Add a
      regression line to show the trend."
      Pairs with: Pearson r, Spearman ρ, regression

6. **Longitudinal graphs (from Table, repeated measures):**
   
   l. **Time Series**
      "One line per group showing a measure over time."
      Pairs with: trend visualization, pre/post designs
   
   m. **Time Series with CI**
      "Group average with confidence band. Shows both the trend
      and the uncertainty."
      Pairs with: repeated measures, group comparisons over time
   
   n. **Spaghetti Plot**
      "Individual trajectories across conditions. Each line is one
      subject. Shows individual variability within the group pattern."
      Pairs with: repeated measures, within-subject designs

7. **Quick reference table:**
   | Question | Graph | Test |
   |----------|-------|------|
   | What does my data look like? | Histogram, Violin | @emlDescribe |
   | Are two groups different? | Violin, Box, Bar | t-test, Mann-Whitney |
   | Before and after? | Spaghetti, connected dots | Paired t, Wilcoxon |
   | 3+ groups different? | Violin, Grouped | ANOVA, Kruskal-Wallis |
   | Two variables related? | Scatter | Pearson, Spearman |
   | Change over time? | Time Series, CI, Spaghetti | Repeated measures |
   | What's in my signal? | Waveform, Pitch, Spectrum, LTAS | Acoustic analysis |

**Graph types featured:** All 14.

---

## 3. Technical Architecture

### 3.1 File Structure

```
plugin_EML_Praat_Tools/
  tutorial/
    eml-stats-tutorial.praat        ← main launcher + module dispatch
    tutorial-common.praat           ← shared drawing/navigation procedures
    tutorial-module-01.praat        ← Module 1 implementation
    tutorial-module-02.praat        ← Module 2 implementation
    ...
    tutorial-module-10.praat        ← Module 10 implementation
```

Each module is a separate file loaded via `runScript:` (not `include`
— they share no procedures except through `tutorial-common.praat`
which IS included by the launcher).

### 3.2 Shared Procedures (tutorial-common.praat)

| Procedure | Purpose |
|-----------|---------|
| `@tutDrawPage` | Clear content area, draw header, draw nav hint |
| `@tutDrawTitle` | Module title card with part label |
| `@tutDrawText` | Wrapped text in content area at specified y |
| `@tutDrawHighlight` | Same as tutDrawText but in highlight color |
| `@tutDrawSubViewport` | Set up a drawing area within the content zone |
| `@tutRestoreViewport` | Reset to full 0–100 axes after drawing |
| `@tutWaitAdvance` | Wait for →/click/space (advance) or ← (back) |
| `@tutDrawButton` | Clickable button rectangle with label |
| `@tutCheckButton` | Check if last click hit a button |
| `@tutDrawProgressBar` | Module progress indicator |
| `@tutDrawHomeScreen` | Module selection grid |
| `@tutThreeLineReset` | Font metric decontamination (Section 4 bug) |
| `@tutDrawDotPlot` | Reusable: dots at categorical x, numeric y |
| `@tutDrawMiniHistogram` | Reusable: small histogram in sub-viewport |
| `@tutDrawMiniViolin` | Reusable: small violin in sub-viewport |
| `@tutDrawMiniBoxPlot` | Reusable: small box plot in sub-viewport |
| `@tutDrawMiniScatter` | Reusable: small scatter in sub-viewport |
| `@tutAnimateDots` | Drop dots into place one by one |
| `@tutDrawConnectedDots` | Paired data with connecting lines |
| `@tutDrawDecisionNode` | Flowchart node for Module 9 |

### 3.3 Color Palette

| Role | Color | RGB |
|------|-------|-----|
| Background | Dark blue-gray | {0.15, 0.18, 0.22} |
| Title text | White | {1, 1, 1} |
| Body text | Cream | {0.92, 0.90, 0.85} |
| Highlight (new term) | Gold | {1.0, 0.85, 0.3} |
| Data group A | Blue | {0.35, 0.55, 0.85} |
| Data group B | Orange | {0.90, 0.55, 0.25} |
| Data group C | Teal | {0.25, 0.75, 0.65} |
| Annotation/stats | Light gray | {0.75, 0.75, 0.75} |
| Axis/grid | Medium gray | {0.45, 0.48, 0.52} |
| Mean line | Red | {0.85, 0.3, 0.3} |
| Median line | Green | {0.3, 0.75, 0.4} |
| Navigation hint | Dim gray | {0.5, 0.5, 0.55} |
| Button fill | Muted blue | {0.25, 0.35, 0.50} |
| Button hover | Lighter blue | {0.35, 0.45, 0.60} |

### 3.4 Layout Constants

```
headerY = 92          # top of title area
contentTop = 85       # top of content area
contentBottom = 8     # bottom of content area
navY = 3              # navigation hint baseline
drawAreaLeft = 15     # left edge of drawing sub-area
drawAreaRight = 85    # right edge
drawAreaTop = 75      # top of drawing sub-area (varies)
drawAreaBottom = 15   # bottom of drawing sub-area
progressY = 96        # progress bar
```

### 3.5 Navigation State Machine

```
Module state:
  currentModule (1–10)
  currentPage (1–N per module)
  maxPageReached (for progress tracking)
  returnToHome (flag for ESC behavior)

Per page:
  @tutDrawPage clears content, draws header + nav
  Module procedure handles content drawing
  @tutWaitAdvance returns:
    1 = advance (→, click, space)
    2 = back (←)
    3 = home (ESC)
    4 = quit (Q or second ESC)
```

### 3.6 Object Lifecycle

| Module | Objects Created | Kept? |
|--------|----------------|-------|
| 1 | 6 Sounds (vowels), tutorialData Table | Sounds removed, Table kept |
| 2 | Extends tutorialData to 30 rows | Table kept (modified in place) |
| 3 | (uses existing Table) | — |
| 4 | (uses existing Table) | — |
| 5 | Adds subject column to tutorialData | Table kept (modified) |
| 6 | Extends to 3 groups or creates new Table | Kept |
| 7 | Adds speaking_F0 + singing_F0 columns | Table kept (modified) |
| 8 | Creates timeCourse Table (10 subj × 4 timepoints × 2 groups) | Kept |
| 9 | (uses existing Tables) | — |
| 10 | Creates demo Sound, Pitch, Spectrum, Ltas for gallery | Kept |

On tutorial exit, all tutorial-created objects remain in the Objects
list. A cleanup prompt offers to remove them.

### 3.7 Demo Window Technical Constraints

From COMMANDS_DemoWindow.txt:

1. **Three-line reset** before every drawing procedure (Section 4 bug)
2. **Y-axis: 0 = bottom** (inverted from Picture window)
3. **Axes: 0, 100, 0, 100** reasserted before click detection
4. **No Polygon Paint:** — use scanline rasterization for filled shapes
5. **demoPeekInput() unsafe during animation** on macOS — no input
   checking during animation loops
6. **`demo Font size:`** for sizing, `demo Helvetica` to flush metrics
7. **Selective repaint** (Paint rectangle over content area) instead of
   `demo Erase all` to reduce flicker

### 3.8 EML Stats / Graphs Include Dependencies

The tutorial script needs the full EML Stats library for live
computation but does NOT use EML Graphs draw procedures (they target
Picture window, not Demo window). All tutorial visualizations are
hand-drawn with `demo` prefix commands.

```
include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-output.praat
include ../stats/eml-inferential.praat
include tutorial-common.praat
```

---

## 4. Scope Assessment

### What this IS:

An interactive, self-paced statistics curriculum built into Praat's
Demo window. Teaches statistical thinking from absolute zero to
"I know which test to run and what the output means." Uses real
audio, real measurements, and real statistical computations. Creates
objects the user can explore after the tutorial.

### What this is NOT:

- Not a replacement for the wizard (Module 9 bridges TO the wizard)
- Not a showcase of the EML Graphs plugin (that's the current
  eml-stats-demo.praat — which should remain as a separate script)
- Not a textbook (brief, visual, interactive — not comprehensive)

### Estimated development time:

| Component | Estimate |
|-----------|----------|
| tutorial-common.praat (shared procedures) | 3–4 hours |
| Module 1 (What Is Data) | 2–3 hours |
| Module 2 (Looking at Data) | 2–3 hours |
| Module 3 (Describing Data) | 3–4 hours |
| Module 4 (Two Groups) | 3–4 hours |
| Module 5 (Before and After) | 2–3 hours |
| Module 6 (3+ Groups) | 3–4 hours |
| Module 7 (Correlation) | 2–3 hours |
| Module 8 (Time) | 2–3 hours |
| Module 9 (Decision Tree) | 2–3 hours |
| Module 10 (Gallery) | 2–3 hours |
| Home screen + navigation + polish | 2–3 hours |
| Testing + debugging | 3–5 hours |
| **Total** | **~30–42 hours** |

This is significantly larger than the 1–1.5 hour estimate on the
blocker list, which assumed revising the existing script. This is a
new product.

### Suggested phasing:

**Phase A (MVP — release blocker):** Modules 1–5 + 9 + home screen.
Covers the core curriculum: data → describe → two groups → paired →
decision tree. ~18–24 hours.

**Phase B (complete — post-release):** Modules 6, 7, 8, 10.
Adds k-group, correlation, time series, gallery. ~12–18 hours.

---

## 5. Open Design Questions

1. **Animations:** How much animation? Point-by-point dot drops are
   compelling but slow. Trade-off: engagement vs. user patience.
   Suggest: animate key moments (first dot plot, histogram morph),
   use instant drawing for repeated concepts.

2. **Module 3 depth:** @emlDescribe produces 15+ outputs. Show all of
   them (comprehensive but long) or focus on the most important 8–10
   (mean, median, SD, SEM, IQR, range, skewness, CI)?
   Recommendation: Show all, but group into tiers — "essential"
   (always look at these) and "advanced" (useful when you need them).

3. **Interactivity level:** The dot plot "click where you think the
   middle is" concept — how many interactive moments per module?
   More interactivity = more engagement but more code complexity
   and more Demo window click-detection gymnastics.

4. **Sound generation parameters:** What base F0 ranges for the
   synthetic vowels? Suggest: female-range (180–260 Hz) to match
   the voice pedagogy audience. Configurable?

5. **Persistence:** Should tutorial progress persist across sessions
   (via preferences file)? User could resume where they left off.
   Adds ~2 hours of development.

6. **Module 10 rendering:** The gallery needs to show all 14 graph
   types in the Demo window, but EML Graphs procedures target Picture
   window. Two options:
   a. Reimplement mini versions for Demo window (significant work)
   b. Draw in Picture window, then show screenshots/descriptions in
      Demo window (easier but breaks immersion)
   c. Hybrid: simple graphs (dots, lines, bars) reimplemented;
      complex ones (violin KDE, spectrum) shown as pre-rendered
      images or described verbally
   Recommendation: option (c).

7. **Relationship to existing eml-stats-demo.praat:** Keep both?
   The existing script is a 30-second "look what we can do" showcase.
   The tutorial is a 30-minute learning experience. Different purposes.
   Recommend: keep both. Rename existing to `eml-stats-showcase.praat`.
