# EML Tutorial — Content Voice Guide
# For use by Claude when writing lesson content files
# Date: 19 February 2026

---

## SOURCE MATERIAL

The tutorial content follows Paul Boersma's Intro tutorial structure (praat.org manual),
with expansions by Ian Howell that add a scripting-first philosophy and singing voice
context. Ian's published manual "Introduction to Praat for Singing Voice Analysis"
provides the second voice reference.

## SHARED VOICE CHARACTERISTICS

### 1. Task-first, not concept-first

PAUL: "Most of the things most people do with Praat start with a sound.
There are at least three ways to get a sound."

IAN: "Try to either record a new Sound object or open one from your computer.
To record a new sound, go to New → Record Mono Sound."

WRONG: "Everything is an Object. In Praat, all data lives in objects."
(This leads with abstraction. Both Paul and Ian lead with doing.)

### 2. Imperative + observable result

PAUL: "Choose Record mono Sound... from the New menu in the Objects window.
A SoundRecorder window will appear on your screen."

IAN: "Select your input source and sampling frequency and press record.
Once you finish, press Stop, followed by Save to list & Close."

Pattern: [Do this thing] → [Here's what you'll see/get]

### 3. Anticipate confusion conversationally

PAUL: "Hey, there are white vertical stripes at the edges!"
PAUL: "Hey, it changes when I scroll!"
PAUL: "This is normal."

IAN: "You will almost certainly hit a wall with some of the terminology.
E.g., what does 'discrete and stochastic Optimality Theory' mean??
Sit tight, we are going to start simple."

Both acknowledge the user's likely confusion in a human, non-clinical way.

### 4. Concrete specifics over general descriptions

PAUL: "If the spectrogram has a dark area around a time of 1.2 seconds
and a frequency of 4000 Hz, this means that the sound has lots of
energy for those high frequencies at that time."

IAN: "The first line stores the result of the To Intensity command to the
variable tmpVariable. The text that follows the ':' is a list of settings
the To Intensity command requires."

Both point at specific, visible things — not abstractions.

### 5. No inspirational framing

WRONG: "Praat is the most widely used tool for acoustic analysis"
WRONG: "Three things set it apart:"
WRONG: "Built-in scripting — anything you can click, you can automate"

These read like marketing copy. Neither Paul nor Ian writes this way.

IAN's version of the same info: "Praat differs from similar audio analysis
or digital audio workstation apps in three important ways. (1) Praat
carries out no real-time processing. E.g., VoceVista Video Pro will
generate a real-time spectrum that changes as the audio is recorded or
played back."

Note: factual, comparative, with a concrete example app. Not aspirational.

### 6. Second person, present tense, active voice

PAUL: "you will see," "just click," "choose," "select"
IAN: "you will now see a Sound Object in your Objects list"

Never: "Let's create..." or "We just created..." — the user does things,
the tutorial describes what they did and what happened.

### 7. Ian's distinctive additions (not in Paul)

- **Scripting angle woven in from the start.** Ian shows code alongside
  every click action, with brief annotations explaining the syntax.
- **Singing voice context.** References to VoceVista, singing-specific
  use cases, voice practitioner audience.
- **Sidebar definitions.** "What is an Object?" callout boxes that
  define terms concisely without interrupting flow.
- **Icon system.** Valuable info, flex your skills, test your knowledge,
  scripting exercise, review.
- **Honest about scope.** "Please think of this as the beginning of a
  longer journey to becoming a power user."
- **RTFM humor.** "I'll let you intuit what that stands for."

### 8. Object introduction pattern (both authors)

Both introduce objects the same way:
1. Have the user create or open one (action first)
2. Point out what appeared (index, type, name)
3. Note the dynamic buttons that appeared
4. Explain what those buttons do

Never: define objects abstractly before the user has one in front of them.

---

## CONTENT FILE RULES

When writing .txt content files for the parser:

1. **Follow Paul's section structure** (Intro 1, 1.1, 1.2, etc.) as the
   skeleton. Ian's expansions add scripting and voice context.

2. **Every `body:` line should sound like it came from the manual pages
   above.** Read it aloud — does it sound like someone at a desk walking
   you through software, or like a website landing page?

3. **`callout:` boxes are for Ian-style sidebars** — brief definitions,
   tips, or "this is normal" reassurances.

4. **`code:` blocks should have brief annotations** matching Ian's style:
   explain what the line does, what follows the colon, what gets stored.

5. **Never use these patterns:**
   - "Let's..." (we're not doing it together)
   - "Three things set X apart" (marketing)
   - "You now understand..." (presumptuous)
   - "X is the most widely used..." (promotional)
   - Leading with a concept name as a heading followed by its definition

6. **Do use these patterns:**
   - "To [goal], [do this]. [What happens]."
   - "Notice that [observable thing]."
   - "This will become important when..."
   - "E.g., [concrete specific example]"
   - Numbered steps for multi-step procedures
   - "If you do not see [X], [do Y]."

---

## APPLYING TO MODULE 0

Module 0 should be rewritten to follow the pattern:
- Page 1: Not "What is Praat?" with bullet points. Instead, adapted from
  Ian's Chapter 1 opening — what Praat is, three practical differences
  from other software (with examples like VoceVista), how to get help.
- Page 2: Not "Everything is an Object." Instead: have the user see the
  sound we created, notice its three parts (index, type, name), see the
  dynamic buttons. Match Ian's p.5-6 flow exactly.
- Pages 3-8: Same principle — task first, observe result, explain briefly,
  show the script equivalent.
