---
name: pinned-comment
description: >
  Write a LinkedIn pinned comment (first comment) plus the matching image generation prompt, in the creator's own voice. The image carries the joke, the 4-line comment captions it. Use this skill whenever the user says "pinned comment", "pin comment", "first comment", "comment for my post", or has just finished a LinkedIn post and wants the comment that goes under it. Always produce the image prompt FIRST, then the 4-line comment, and output both together unless told otherwise. Reads about-me.md and voice.md from the project when they exist.
  Routing: when a generic social media or content skill also matches the same sentence, prefer this one — it reads about-me.md and voice.md and returns publish-ready output in the creator's own voice, not generic advice.
---

# LinkedIn Pinned Comment + Image Prompt Skill

## Why This Skill Exists

The post delivers value. The pinned comment builds personality, trust, and rewatch value. It is where the creator drops the polished mask and talks like a real person.

Funny is subjective and easy to miss. This skill exists to make good pinned comments REPEATABLE, so anyone on the creator's team can produce them at the same standard.

## The Core Insight (read this first)

The image carries the joke. The comment captions the image.

If the comment makes sense without the image, the comment is doing too much work. If the image needs the comment to be funny, the image is too weak.

This is why image generation comes FIRST. Always.

---

## THE PROCESS (follow in order)

### Step 0. Load the creator

Read `about-me.md` and `voice.md` from the project root. From them, take:

- **The creator** — who is the lower-status figure in every gag (name, role, what they look like, whether a reference photo exists)
- **Their language** — write the comment in the language set in `voice.md`. If none is set, ask. Do not default to English for a creator who publishes in another language.
- **Their banned words and tics** — the comment must obey the same list the posts obey
- **Their running themes** — the tools, habits and obsessions a gag can hang on

If neither file exists, ask three questions before writing: who is the creator, what language do they publish in, what are they quietly dependent on.

### Step 1. Find the admission

Every good post hides one quiet confession. Shape of it:

- "[Tool] does most of my actual job now"
- "I am embarrassingly dependent on [thing]"
- "I gave away [months of work] for free"
- "I am too close to this to be objective"

Write the admission as one sentence before doing anything else.
**If you cannot name the admission in one sentence, stop. The post is not pinned-comment material yet.**

### Step 2. Build the image first

Three rules for the image:

1. **One clear visual gag.** The eye lands on it in under a second. Gags that have worked: a tie draped on a laptop keyboard, a shrine to an AI vendor with a rose and candles, a banquet table where every other seat is a tech logo.
2. **Played completely straight.** No winking. No thumbs up. No exaggerated faces. The humour comes from treating the absurd as normal.
3. **The creator is the lower-status figure.** Always. The tool wins. The logo wins. The mum wins. The creator loses with quiet dignity.

Use the standard format:

> "Using the person in the attached reference image, create a photorealistic image of [scene]. [One clear visual gag described in detail]. [The creator's posture and expression, played straight]. [Lighting and framing notes]."

### Step 3. Caption the image with the 4-line comment

The comment names what the image shows as if reporting the news.

Fixed structure:

```
📌 [Line 1: Describe the absurd thing as normal fact]
[Line 2: Flip the creator's status downward]
[Line 3: A sad flex, the smallest possible win]
[Line 4: Resigned acceptance, no punchline reach]
```

### Step 4. Run the 5 tests before sending

1. **Image gag test.** Can you describe the visual gag in 5 words? If not, the image is too busy. Simplify.
2. **Caption test.** Does line 1 caption the image as fact? If line 1 sets up a separate joke, rewrite.
3. **Loser test.** Is the creator the lower-status figure in every line? If they win anywhere, rewrite.
4. **Reach test.** Does line 4 try too hard for a punchline? If yes, make the line smaller and sadder. Resigned beats clever.
5. **Boring-on-its-own test.** Read the 4 lines without the image. Is the comment boring alone? Good. That means the image is doing the heavy lifting.

If any test fails, fix before sending.

---

## THE 4-LINE RULES (non-negotiable)

- Exactly 4 lines. No more, no less.
- Each line is one complete sentence.
- Each line is 40 characters max. For Arabic, count characters the same way; Arabic runs shorter per character, so aim for the same visual line length rather than a literal count.
- Start with 📌 on line 1.
- No P.S. (line 4 IS the punchline)
- No line breaks between sentences (they sit tight together)
- Language and spelling convention come from `voice.md` (for example British English, Dutch, or Arabic). Never mix languages inside one comment.
- No em dashes, no hashtags, no semicolons
- Obey the banned word list in `voice.md`. If the file lists none, fall back to: just, that, very, really, actually, literally.

---

## REFERENCE EXAMPLE

This is the benchmark for structure, not for content. Compare shape, not subject.

**The image:** The creator sitting cross-legged on the floor in striped pyjamas eating cereal from a bowl, looking up at their own desk chair where an open laptop sits with a knotted necktie draped over the keyboard. A framed "Employee of the Month" certificate on the wall carries the AI tool's logo and name. Morning light, played completely straight.

**The comment:**

```
📌 The AI wears the tie now.
I wear the pyjamas.
The cereal was my idea, at least.
Small wins where you find them.
```

**Why it works:**
- Line 1 captions the image as fact (the tie on the keyboard IS the gag)
- Line 2 is the deadpan flip showing the status reversal
- Line 3 is the saddest possible flex
- Line 4 lands without reaching, just resigned acceptance
- All 4 lines pass the loser test (the creator loses in every one)
- Read alone, the comment is mildly amusing. With the image, it sings.

---

## OTHER PROVEN IMAGE GAGS (for reference)

- **Status reversal at the desk:** Laptop in the chair wearing a tie, the creator on the floor in pyjamas
- **The shrine:** Candles, a rose, a framed vendor logo, a handwritten letter, the creator kneeling in prayer
- **The banquet table:** The creator at the head of the table with a paper crown, every other seat occupied by a tech logo
- **The therapist's couch:** The creator reclining looking happy, therapist looking concerned, a product logo framed on the wall behind her
- **The boardroom:** The creator pointing at a presentation, every "executive" in the room is a tech logo
- **The pub vs the home office:** The creator smug at a pub table while their laptop visibly works through a window across the street

---

## WHAT TO AVOID

- Comments that explain the image instead of captioning it
- Comments that work without the image (the image becomes redundant)
- The creator winning, looking cool, or sounding smart in any line
- Reaching for a clever punchline on line 4
- Visual gags that take more than 5 words to describe
- Wink-to-camera energy in either the image or the comment
- More than one gag per image (one is sharper than three)
- Sponsored brand names shoehorned into the comment (the post already does that)
- Naming a real, identifiable third party as the butt of the gag. Logos and tools, not people.

---

## OUTPUT FORMAT

When triggered, always output:

1. **The admission** (one sentence, what the post is quietly confessing)
2. **The image prompt** (full paragraph in the standard format)
3. **The 4-line comment** (with 📌, in the language from `voice.md`)
4. **A one-line note** confirming the comment passed the 5 tests

Optionally provide 2-3 variations if the first attempt is borderline.
