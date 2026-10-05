# draft-commit — message drafting notes

Notes from real use of the `draft-commit` ritual, recorded so a later revision can fix the cause rather than
the symptom. Each entry is a real failure, not a hypothetical.

**Where the checks come from.** D-1 to D-4 were found by critiquing drafts against this file and having the
draft still be wrong. The general reasoning discipline in Step 3.5 — surface assumptions, prefer the simpler
message, volunteer what only you noticed — is adapted from `swt:think`, whose first two sections are portable
guidelines and whose remaining sections describe that tool's task workflow. The workflow is retired in the
repositories this ritual serves, so only the reasoning was taken and it was brought here rather than left in
an archived skill elsewhere.

**Status:** D-1 through D-5 are all applied. `SKILL.md` opens Step 3 with *establish purpose* and gates the
subject on contribution; Step 3.5 is a self-critique pass the agent runs before presenting a draft to the
human, covering whether the main line can be followed, whether its words are ordinary English, and whether
each bullet describes the situation rather than the mechanism. Each entry records a failure that passed
every check in place at the time. `scripts/lint.sh` checks bullet length as a warning. All four entries
record a failure that passed every check in place at the time.
**Source:** Session 2026-10-02, HyperGo work; revisited 2026-10-04.
**Scope:** Defects in how the agent derives the subject and bullets from a diff.

---

## D-1 — Subject described contents instead of contribution

**Severity:** High. Produces a technically accurate, misleading history.

### What happened

Committing the Small Steps trial application. The first draft was:

```
feat(tasks): add single-user task list with idempotent form submission

* seeds three tasks and reports pending and total counts, rendering every title as escaped text
* accepts additions through ordinary browser forms while rejecting blank and overlength entries
* keeps a repeated submission from creating a second task, including when sixteen retries arrive at once
* completes a task without renumbering or reordering, and treats a repeated completion as a no-op
* stays fully operable without client scripting, and serves an offline page when the network is unavailable
* exercises the task domain directly, so its rules are verified without any server involvement
```

Every bullet was true. Every bullet described the application. None of them said what the repository is
for.

The repository exists to evaluate a framework. Its own brief states the purpose: *"recreate the synthetic
Small Steps PWA from a written brief and use it to evaluate HyperGo."* A person reading `git log` would
have concluded this was an ordinary to-do application with no particular significance — the opposite of
the actual situation, where this repository is the evidence base for a module-layout decision and an
idempotency pattern adopted framework-wide.

The corrected subject was `feat(trial): demonstrate a generated foundation becomes a correct application
from a brief`. Same facts, different claim.

A second, milder instance occurred in the same session. A documentation-only commit was drafted as
`establish authority documents and record verified implementation state`, which describes what the files
contain rather than why they were written. Accurate, but closer to a folder listing than to a claim.

### Root cause

The quality checklist asks:

- *"Am I describing a problem solved, not steps taken?"*
- *"Would someone understand the impact without knowing implementation?"*

Both are satisfiable by a purely functional description. A to-do application that handles duplicate
submissions correctly **does** solve a problem and **does** have impact. Nothing in the checklist asks
what a change **contributes** — what it is evidence of, what it makes possible, or why this particular
repository needed it.

Outcome-focus is necessary but not sufficient. Focus must be anchored to the repository's purpose, or
"outcome" silently collapses into "the feature's behavior."

### Proposed change

Add a step before Step 3 — **establish purpose**:

> Read the repository's own statement of purpose (README, PRD, brief, issue) and write one sentence
> naming what this change is evidence of, enables, or settles.

Then gate the subject on that sentence:

> Does the subject say what this change *contributes* to the repository, or only what it contains?

Two supporting checklist items:

- If this repository exists to prove, evaluate, or demonstrate something, does the history say so? A
  reader of the log should not have to open the README to learn why the code matters.
- When a change is evidence rather than functionality, say so in the subject. "demonstrate", "prove",
  "verify", and "record" are load-bearing verbs for that case.

### Applied

Both items are now in `SKILL.md`. Step 3 opens by establishing the purpose sentence, and the subject is
gated on whether it says what the change contributes.

The second part of this entry also needed fixing, and that is what became Step 3.5. The rule above tells
the agent what a good message looks like, but nothing required it to check its own draft against that rule
before a human spent time reading it. On 2026-10-04 the logging-slice draft reproduced this exact failure
while being written — three of four bullets described mechanism behaviour rather than contribution — and
was caught only because the human asked for a critique pass first.

A lint cannot catch this. The bad draft passed the gate: it was well-formed prose describing real changes.
The check has to be a deliberate reading step, and it has to happen before the human is asked to approve
something, or the human becomes the error detector the tool was supposed to replace.

### Detection note

Nothing mechanical catches this. The lint passed on the bad draft without complaint, because the draft
was well-formed prose describing real changes. The check has to happen in the agent's reading step.

---

## Relationship to the existing "summarize outcome bullets" rule

An earlier revision added the rule that a subject must summarize its outcome bullets rather than list
them. That rule works, and this failure is distinct from it: the bullets were correctly summarized, and
they were all misaimed. Both the bullets and the subject that summarized them described behavior instead
of contribution.

The current rule constrains the relationship between subject and bullets. It says nothing about what
the bullets themselves should be about. That gap is what D-1 falls through.

---

## D-2 — A subject that names a decision instead of a behavior

**Severity:** High. Passes every existing check and is still unreadable.

### What happened

Committing the response-shape selection slice. The first draft's subject was:

```
feat(web): close the response-shape half that origin-based CSRF protection deferred
```

The human's reply was: *"i dont understand the main line"*.

The change was easy to state plainly: a scripted request is answered with a bare fragment instead of
a whole page. The subject said none of that. It named a half of a security decision and pointed at a
chapter in the project's record, leaving the reader to infer what the software now does.

An earlier revision made it worse in the other direction. That one read `give a client-controlled
header a bounded role` — a summary of the design constraint rather than of the behavior, and equally
not followable.

### Root cause

This is not D-1. D-1's drafts were behaviorally precise and aimed at the wrong target: they described
what the code did instead of what it contributed. These drafts are aimed correctly and describe
nothing a newcomer could follow, because the **subject of study is the decision** rather than the
change in behavior.

Every check the critique loop ran passed both versions:

- *Does the subject say what it contributes?* Yes — closing a deferred decision is a contribution.
- *Could a reader reconstruct the implementation?* No — no implementation detail leaked.
- *Does it stand alone?* Yes — grammatically complete.
- *Is it vague?* By the usual test, no — it names a specific decision, a specific half, and a
  specific prior record.

The gap was that no check asked whether the main line could be **stated**. "Contributes something" and
"can be understood" are independent properties, and satisfying the first says nothing about the
second. A message can be a perfectly good account of why the change exists and still fail to say what
the change *is*.

The deeper hazard: this failure is invisible to the person who wrote it. The writer holds the whole
diff in their head, so the subject feels self-explanatory — it is summarizing, for themselves, work
they already understand. Only someone without that context hits the wall.

### Proposed change

Make followability the first item of the critique, before contribution:

> State the change back as plain behavior in one sentence, the way you would to a colleague who has
> not opened the diff. If you cannot without using a project's internal vocabulary, the subject is
> aimed at the repository rather than at a reader.

And separate the two ideas explicitly, so "abstract" stops being treated as the opposite of "concrete":

> A subject may name a settled decision, a boundary, or a guarantee and still be concrete. What makes
> a subject vague is that its subject of study is the decision rather than the behavior. Put the
> behavior in the subject; what decision it settles is a bullet.

The operational test: **if a subject can only be understood by someone who already knows the project,
it has failed** — and that is a different test from the contribution question.

### Applied

Both are in `SKILL.md`. The critique loop opens with *can you follow the main line?*, states the
behavior-plainly test, and separates "names a decision" from "is vague". The Quality Checklist carries
the followability item.

### Detection note

Nothing mechanical catches this, and neither does the writer. The lint passes; the critique passes;
the draft reads well to the person who wrote it. The check is a deliberate act of restating the change
as if for a stranger, which is why it has to be a named step rather than an expectation.

---

## D-3 — Coined terms borrowed from the project's own vocabulary

**Severity:** Medium. Followable to the team, opaque to everyone else.

### What happened

The draft that fixed D-2 opened with `feat(web): answer a scripted request with a page fragment
instead of a whole page`. The human asked: *"what do you mean by scripted request?"*

"Scripted" was the project's word throughout — the specification's own phrase, used correctly in every
document, understood by everyone who had read them. In it, the word carried the whole distinction
between a browser navigating to a URL and JavaScript fetching a piece of a page. To anyone else it is
empty.

Rewritten as *a request made by JavaScript*, the sentence explains itself with no context at all.

### Root cause

D-2's fix is a step in the right direction but stops one short. "Can you follow the main line?" is
answered in the writer's own head, where the vocabulary is free. The check has to ask not only whether
the line is followable but whether it is followable **in ordinary words**.

Software projects accumulate terminology as a byproduct of design, and then use it as if it were
shared knowledge. It is not. Terms like *island*, *scripted*, *enhanced*, *native*, *shape*, *replay*,
*admission* and *guard* all have ordinary English meanings that are close enough to be seductive and
wrong enough to mislead. A reader who knows the word "island" will picture something tropical.

The failure is more likely after a design discussion than before one, because by then the vocabulary
has been used several times and feels settled. It is also the one failure the writer is least able to
notice: coined vocabulary is *more* legible to the insider, not less, because it compresses a lot of
agreed meaning into one word.

### Proposed change

Add to the followability check:

> Flag every word that this project invented, defined in its own record, or uses to mean something other
> than its ordinary meaning. The plain word is nearly always available. When the plain word feels less
> precise, the precision belongs in a bullet — the headline's job is to be understood, not to be exact.

And state the operational substitution, because naming the abstract rule is not enough:

> A request made by JavaScript for "scripted". Part of a page for "island". A size limit for "bound".

A coined term earns a place in a subject only when it names a genuine load-bearing concept with no
plainer synonym, and even then it is spelled out in the first bullet.

### Applied

Both are in `SKILL.md`. The followability check carries the coined-terms subsection with the
substitutions, and the Quality Checklist asks whether every word in the subject is ordinary English a
reader outside the project would use.

### Detection note

The human has to ask. There is no signal available to the writer, because insider vocabulary is the one
thing about a draft that reliably *feels* correct. The only mitigation is to ask the substitution
question deliberately on every subject: *what is the ordinary English for this word?*

---

## D-4 — The critique inspected the subject and left the bullets alone

**Severity:** Medium. The checks were all about the subject; the bullets went unexamined.

### What happened

The response-shape slice went through three critique passes. Each one examined the subject closely and
critiqued the bullets only in the sense of asking whether they *said* something — duplication, evidence
in the wrong place, missing reassurance. Nobody read a bullet for legibility.

When the human finally asked for the bullets to be critiqued, four problems were visible immediately:

- A bullet ran to 34 words with three modifiers stacked before the verb, putting the point where
  nobody reads.
- The coined terms cleaned out of the subject — "shape", "fragment" — were still sitting in bullet 2.
  The subject had been fixed and the bullets left paying the same cost.
- A 45-word bullet compressed the entire security argument into one clause a reader could not check.
  It was the most important claim in the message and the least checkable one.
- A bullet read "no page-part lookup is included". No such mechanism exists. That was an invented
  plain-sounding name for island dispatch, and it is worse than the technical term, because a reader
  goes looking for something that was never built.

### Root cause

The critique loop was written around the subject, because that is where D-1 and D-2 had both failed.
Checks accumulated for the subject and none for the body, and the assumption that fixing the subject
fixed the message proved wrong in the specific way that mattered most: the coined terms and the
security reasoning were in the bullets.

Two of these are mechanical and had no check at all. Bullet length is countable. Reappearing terminology
is visible once you look for it, but only if looking is a named step rather than an expectation.

### Proposed change

Add a bullet-legibility check to the critique, after the subject is settled:

> Read each bullet on its own and check four things: one clause before the verb; the term rule applies
> to bullets too; no invented plain-sounding name for a missing thing; under 30 words.

The coined-terms rule needs restating there explicitly, because the natural reading is that it applies
to the subject only. It does not — the reader pays for the term wherever it appears.

And make the countable part mechanical. Bullet length joined the lint as a warning, alongside WIP
markers and forward-looking phrasing: rejoining wrapped lines, counting words, warning over 30 without
failing. A warning rather than an error because a long bullet is a judgement call, not a defect — but it
should not require the human to notice it.

### Applied

Both are in place. `SKILL.md` Step 3.5 has the bullet-legibility check as item 6, the Quality Checklist
carries the two bullet questions, and `scripts/lint.sh` reports bullet length as check 7. The check was
verified against a deliberately long bullet and against a real draft: it warned on the 41-word sample and
caught a 45-word bullet in a draft that had already passed every other check.

### Detection note

The human asked. Nothing in the ritual prompted a close read of the body, which is the same shape as
D-1 and D-3 — the gap is where nobody thought to look. The difference here is that the fix is partly
mechanical, so it should not recur the way the others did.

---

## D-5 — Bullets that describe the mechanism in ordinary words

**Severity:** High. Passes every legibility check in place at the time.

### What happened

Committing the limiter sweep. After fixing the subject three times, the bullets still produced this
exchange:

> **me:** * clearing out visitors who had gone quiet then ran inside the wait that every other request
> needs, so that attacker's traffic made all of them queue behind the cleanup
>
> **human:** rephrase bullet 2
>
> **me:** * with no room left, tidying up ran on whichever unlucky request arrived next, so one
> visitor's flood made every other visitor wait while the table was sorted out

Then: *"do the same to the bullets what i did to the main line. i was really trying to extract the
context fo the change"*.

The first bullet is not jargon. It has no coined term, invents no name, sits under thirty words, and
reaches its verb in one clause. It passed all four sub-checks of bullet legibility. It was still a
description of a mutex — a lock — phrased in words that happen to be ordinary. The reader has to
picture a concurrency primitive to get anything from it, and a reader who does not write this code
gets nothing at all.

### Root cause

The legibility checks were all *mechanical*: length, vocabulary, clause shape. None asked the
question that actually matters — is this bullet about the world or about the code? A bullet can be
lexically immaculate and describe internals.

That gap is invisible from the writer's side for the reason D-3 describes: the writer knows what a
lock is and reads the bullet as a statement about the world, because to them it is one sentence
removed from a real observation. It is not.

The deeper error was mine, and it is worth naming: I applied the plain-language rule to the subject
repeatedly and to the bullets never, treating "make it readable" as a property of the headline. The
human had to ask for the second half twice — once for vocabulary, once for the underlying issue.
That is two rounds of the same lesson, and the lesson is that the rule applies to the whole message.

### Proposed change

Make *situation, not mechanism* the first bullet-legibility check, above the mechanical ones:

> Does the bullet describe what was happening and what it cost, or how the code works? A bullet is
> history, and history is about the world the change happened in. "Ran inside the lock every other
> request needs" is a description of a mutex wearing ordinary words; "ran on whichever unlucky
> request arrived next, so everyone else waited while it tidied" is the same fact as something that
> happened to people.

With the operational test:

> Could a reader who does not write this code still find the bullet true and useful?

And say plainly that the mechanical checks are necessary and not sufficient, because "no coined
terms, under thirty words, verb within a clause" is exactly what the bad bullet had.

### Applied

Both are in `SKILL.md`: the check leads bullet legibility, the Quality Checklist carries the question,
and the sub-checks are marked as necessary rather than sufficient.

### Detection note

The human asked, twice. Nothing mechanical catches it, and the mechanical checks passing is exactly
what creates the false confidence — a draft that satisfies every stated rule and is still unreadable
looks like the rules are sufficient. A check that passes for the wrong reason is worse than a missing
check, because it is taken as evidence.

One further note on the exchange itself: the human's stated purpose was to *extract the context of the
change*, not merely to read it. That is a different reading task than "understand what happened", and
a message that answers it has to carry the situation rather than the mechanism. Worth remembering when
the question is why a bullet exists at all.
