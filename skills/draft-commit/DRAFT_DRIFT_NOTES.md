# draft-commit — message drafting notes

Notes from real use of the `draft-commit` ritual, recorded so a later revision can fix the cause rather than
the symptom. Each entry is a real failure, not a hypothetical.

**Where the checks come from.** D-1 to D-4 were found by critiquing drafts against this file and having the
draft still be wrong. The general reasoning discipline in Step 3.5 — surface assumptions, prefer the simpler
message, volunteer what only you noticed — is adapted from `swt:think`, whose first two sections are portable
guidelines and whose remaining sections describe that tool's task workflow. The workflow is retired in the
repositories this ritual serves, so only the reasoning was taken and it was brought here rather than left in
an archived skill elsewhere.

**Status:** D-1 through D-9 are all applied. `SKILL.md` opens Step 3 with *establish purpose* and gates the
subject on contribution; Step 3.5 is a self-critique pass the agent runs before presenting a draft to the
human, covering whether the main line can be followed, whether its words are ordinary English, whether
each bullet describes the situation rather than the mechanism, whether the bullets support the subject's
claim, whether each records a decision rather than an expected consequence, and whether any relationship
it asserts was actually checked. Each entry records a failure that passed every check in place at the
time. `scripts/lint.sh` checks bullet length as a warning. D-6 through D-9 all surfaced in one session,
on one commit, in which the human removed six of nine bullets and corrected one false claim.
**Source:** Session 2026-10-02, HyperGo work; revisited 2026-10-04 and 2026-10-05.
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
change*, not merely to read it. That is a different reading task than "understand what happened", and a
message that answers it has to carry the situation rather than the mechanism. Worth remembering when
the question is why a bullet exists at all.

---

## D-6 — Bullets that do not support the subject

**Severity:** High. The main line was right and the body was about a different change.

### What happened

Committing the templ integration. The subject was `feat(scaffold): build generated pages from reusable
components`. Five bullets followed, every one of them about the safety machinery: a stale page failing
the build, the check being a test rather than a command, compiling and recording in one step, `dev`
recompiling, a fresh clone building. Not one mentioned a component.

The human's reply:

> you focused on spikes and unit tests rather than reinforcing or deatiling "build gernated pages from
> reusable components"

### Root cause

The critique's subject-accuracy check asks whether the subject summarizes the bullets. Nothing asked the
reverse. A draft can have an accurate subject, bullets that are individually excellent — plain, short,
situation rather than mechanism, no coined terms — and still be a message about something else.

The pull is structural. The adjacent topic is usually the more *articulate* part of the work. Safety
machinery and developer experience generate better sentences than "components take their values as
arguments", because a consequence has an observable shape and a design decision often does not. The
bullets drifted toward what was easiest to say well, and the subject's actual claim went unrepresented
while every legibility check stayed green.

This closes a gap that D-1 identified and did not act on. Its *Relationship to the existing "summarize
outcome bullets" rule* section observed that the rule constrained the subject-to-bullets direction while
saying nothing about what the bullets themselves should be about, and called that "what D-1 falls
through". That observation was correct and was left in place as prose.

### Proposed change

Make the subject-accuracy check bidirectional, and give it an operational test:

> Does the subject still summarize the revised bullets — **and do the bullets still support the
> subject?** A message whose main line is correct and whose body is about a different change is still a
> message about a different change.
>
> The test: if the subject's own key noun appears in no bullet, the bullets are about something else.

### Applied

Both directions are in `SKILL.md` as one check, and the Quality Checklist carries the inverse question
separately so it can be asked on its own.

### Detection note

The human asked. The lint passed and every critique check passed, because each bullet really was a good
bullet — they were good bullets about the wrong thing. Same shape as D-1, D-3 and D-5: the gap is where
nobody thought to look, and it looks fine precisely because each individual element is sound.

---

## D-7 — Bullets recording expected behaviour instead of a choice

**Severity:** Medium-High. Produces a padded message whose length implies more deliberation than happened.

### What happened

The same templ commit went through six bullet revisions. The human removed bullets one at a time, in
four different words:

> 3 is unecessary, i think that is expected

> an edit is never lost is expected for dev

> 4th is an expected behavior for tests. no need to add that

> ofcourse tests will fail if it is not synced with changes in templ templates

The removals: a type error failing the build at a call site; `dev` recompiling templates; a test failing
when generated code is out of date. Six bullets became three, and every survivor records a decision.

### Root cause

No check asked whether a bullet records a *decision*. But most of the available facts about a change are
consequences that follow anyway, and they are the easiest to write because they are the most concrete. "A
test fails when the generated code is stale" is a checkable sentence. "We committed the generated output
rather than ignoring it, which is what the tool recommends, so a fresh clone builds with plain `go build`"
is a choice, and it is the one a reader needs in order to understand the commit.

The tell: a bullet whose claim is a property of the language, the framework, or the tool rather than of
this change.

### Proposed change

Add a check:

> **Choice or expectation?** For each bullet, ask what would be different had we decided otherwise. If
> the answer is *nothing*, the bullet is recording how the tool works, not what we did — and history
> records what was settled.
>
> If adding "and this is surprising" or "which is not what the tool does by default" to the bullet would
> be false, it is an expectation. Cut it.

### Applied

In `SKILL.md` as its own critique item, and in the Quality Checklist.

### Detection note

The human, four times, in four different formulations. Nothing mechanical catches this and neither can
the writer: expected behaviour *feels* like a result, and results are what a commit message is supposed
to contain. The mechanical checks passing is what makes it invisible — each removed bullet was
correct, plain, short, and about the world rather than the code, and therefore satisfied D-5 while
adding nothing.

---

## D-8 — A bullet asserting a relationship that was never checked

**Severity:** High. A reader will act on it.

### What happened

A bullet read: *"two applications written from different plans ship byte-identical components and differ
only in the values handed to them, so the pieces are the product's, not one app's"*.

The human asked:

> i am not really interested in 2 applciations. does this mean that components can be shared by 2 diff apps?

It does not, and the bullet's implication was the opposite of the architecture. Two applications each own
a separate copy, rendered from the same source; nothing is shared at runtime and neither depends on the
other. The bullet was true about the source being identical and false about the relationship that
truth implied — and the relationship was the part that mattered. Stated correctly it is an existing
decision: platform source is application-owned, and components follow that rule rather than departing
from it.

### Root cause

Two failures inside one sentence. The relationship was asserted rather than checked, and the true part
was incidental — identical output is a by-product of generating from one source, not a designed
property. Drafting from the diff hands you the true part for free; the relationship is the part that
requires going and looking.

This is also the failure mode where a plain-language bullet is most dangerous. Rewriting jargon into
ordinary words makes a claim *sound* checkable without making it true, and the rewrite is where the
unsupported inference usually enters.

### Proposed change

Add to bullet review:

> **Does the bullet assert a relationship you verified?** Claims of *shared*, *owned*, *per-application*,
> *isolated*, *identical*, *independent* describe a relationship between things, and a diff usually
> cannot show it — two identical files look like sharing, and the absence of a dependency shows up as
> the absence of a line. Confirm each one, and ask what a reader would *do* differently on the strength
> of it. If nothing, the relationship is decoration; cut it.

### Applied

In `SKILL.md`, folded into the bullet review alongside D-6's key-noun test, since both are about whether
a bullet says more than the work supports.

### Detection note

The human asked, because the bullet said something a reader would act on. Nothing in the diff shows the
negative, and no lint can distinguish a verified relationship from an inferred one — the words are the
same either way.

---

## D-9 — A specific claim written without checking it

**Severity:** Medium. The kind of sentence that is believed precisely because it is the kind of thing
that would have been checked.

### What happened

Recording templ evidence in the project's own record, the agent wrote *"the six emitted components take
their values as arguments"*. There are seven. The number had come from an earlier reading of the file
during the same session and had drifted; nobody counted.

In the same session, a check meant to prove that an uncompiled page is caught **passed on the first
attempt**. It had tested nothing. The edit being made searched for `<h1>HyperGo</h1>`; the file contains
`<h1 tabindex="-1">{ heading }</h1>`, because the heading is a component argument. No edit was made, so
no drift existed, so the test was correct to pass. Re-run against a real change it failed as intended:

```
1 page source changed but was not recompiled; run 'go generate ./...' (stale: shell.templ)
```

Both errors were in material already described as verified.

### Root cause

Two related mistakes. First, a specific, checkable claim is the easiest kind of sentence to write and the
least likely to be doubted, because it feels like the kind of thing that would have been checked — the
number was not a guess, it was a *misremembering*, which is harder to notice than a guess. Second, a
green result is taken as evidence without asking whether the check had anything to look at. The
human-visible symptom of a vacuous check is that it passes immediately.

### Proposed change

Add to the critique, and to the evidence discipline generally:

> - A count in a message or a record is counted, not remembered. If the number is not in front of you,
>   count it before writing it.
> - **A check that passes the first time has not been shown to have teeth.** Before believing it, make a
>   second run in which the thing you expect to trip actually trips. A passing check and a check with
>   nothing to find are indistinguishable from the outside.
> - Report the command that ran and what it printed. A belief that something is true, and a result that
>   shows it, are different things and should not be written in the same voice.

### Applied

In `SKILL.md` as part of the relationship check, with the cross-reference noted there: the project-level
version of this rule belongs to the coordination record's evidence discipline, not here, and duplicating
it would give it two homes and no owner.

### Detection note

Self-caught, on re-verification before presenting — not by the lint, not by the human, and not at the
time. Recorded because the near-miss is the instructive part: both errors sat inside work already
reported as observed, which is the exact condition the evidence discipline exists to prevent.

## D-10 — Structural noise was checked in the bullets but not the subject

**Severity:** Medium. The guidance forbids file paths; the gate only enforced it where it was easiest to
detect, so a subject could name directories freely.

### What happened

Committing a directory rename. A subject was drafted naming both the old and new folder paths:

```
chore: design packages move from .demo/ to fixtures/
```

It passed: `✅ Context: No obvious structural noise detected.` The maintainer rejected it, citing the
guideline that file paths and internal details are forbidden in commit messages. The next draft was
`chore: design packages sit in a visible folder instead of a hidden one`.

The same gap let `chore(fixtures): rename the input folder to fixtures and stop tracking one fixture`
through twice before being rejected for being vague.

### Root cause

The lint's context check scans bullet lines for path-like content. Subjects were never scanned. The
document's own red-flag table lists "Bullet contains `/`" — so the rule was written about bullets and
the gate agreed, while the prose rule ("every word in the subject must be ordinary English a reader
outside this project would use") went unenforced.

A subject naming paths is worse than a bullet doing so: the subject is read first and alone, and two
adjacent paths tell the reader nothing about why the change was made.

### Proposed change

Apply the structural-noise scan to the subject line as well. Additionally, the maintainer's correction
was not only about paths — it was that a path tells the reader nothing. Record that in the check's
failure message so the gate teaches the reasoning rather than the pattern.

### Applied

`lint.sh` now scans the subject for path-like tokens and reports it as a **warning**, not an error: a
legitimate commit may legitimately mention one path, and the agent's judgement decides. The
distinction is deliberate — the noise check is advisory, matching the readability check.

### Detection note

Caught by the maintainer, twice, across two separate commits in one session. Not self-caught: both
drafts were presented as lint-clean, which they were, and the missing check was invisible because the
output said "no obvious structural noise detected".

## D-11 — A warning-only run prints a pass mark and exits zero

**Severity:** Low in effect, high in how it reads. A run with findings looks identical to a clean run.

### What happened

A draft with a 34-word bullet produced:

```
⚠️  Readability: bullet(s) over 30 words detected (warning only).
✅ LINT PASSED (with warnings)
```

It was committed with the warning present. The maintainer later asked why a message with a known
finding had "passed lint" — which is the correct question and the output does not answer it. The
parenthesised qualifier is the only thing separating the two states, and it sits after a checkmark.

### Root cause

The script exits 0 whenever no check *failed*, and prints a checkmark in both cases. A reader scanning
output for a single status character cannot distinguish "nothing found" from "something found, ignored".

This is the same shape as D-9's note that a passing check and a check with nothing to find are
indistinguishable from the outside. Here the gate itself performs the confusion, rather than the agent.

### Proposed change

When any warning fired, the summary line should not carry a checkmark. Print the count of warnings and
make them the summary's subject, so the terminal state of the run answers the question a reader has.

### Applied

`lint.sh` prints `✅ LINT PASSED` only when no warning fired. Otherwise it prints
`⚠️  LINT PASSED WITH N WARNING(S) — review before applying`, and lists which checks warned.

### Detection note

Raised by the maintainer as a question rather than a correction, which is the more expensive form of
the same observation: the ambiguity had to survive long enough for someone to ask about it.

## D-12 — Nothing covered amending a commit that already exists

**Severity:** Medium. The workflow only describes drafting a new commit, so a message that needed
fixing after committing had no defined path.

### What happened

Two commits were made, then the maintainer asked for the first one's subject to be reframed. The
revised message was drafted and recommended without first checking whether that commit had been pushed.
It had — it was three commits back on `main`, with a live remote. Applying the fix would have rewritten
four published commits and required a force-push. That cost surfaced only after a clean rewrite had
already been proposed, and the recommendation had to be walked back.

### Root cause

The skill's flow runs draft → approve → commit → clean up, and stops there. It assumes the commit does
not yet exist. Nothing asks what a proposed message change costs when history already contains it, so
the agent can recommend an operation whose blast radius it has not computed.

The distinction is not cosmetic: rewriting a local commit is routine, rewriting a pushed one changes
what other clones hold and cannot be undone by anyone who has already fetched.

### Proposed change

Add a step before presenting any revision to a message that is already committed: establish whether that
commit is an ancestor of the current tip, and whether it has been pushed. Report the blast radius —
how many commits change hash, and whether a force-push is required — as part of the proposal, not
afterwards.

### Applied

Added as a short subsection under the fine-tune step in `SKILL.md`, with the check commands. It is not
a new ritual: it is the same evidence discipline the critique already requires, applied to history
rather than to wording.

### Detection note

Self-caught, but only after the recommendation had been made. The cost check happened to be run
because amending had been done earlier in the same session for an unrelated reason — which is not a
mechanism, and this is the note that says so.

## D-13 — The bullet block was the default, and each bullet was defended rather than earned

**Severity:** Medium. Produces messages that read as padded, and spends the maintainer's turns on
edits that should never have been drafted.

### What happened

One commit message was drafted six times. It began with three bullets and lost them one at a time,
each removal requested by the maintainer:

- *"the bullets need tightening"* — three bullets became three shorter ones
- *"bullet 2 is just noise"* — the rationale for removing the duplicate copy
- *"maybe we dont need the bullets"* — subject alone

Each cut was correct. The agent's defence at every stage was that the bullet satisfied some part of
the checklist, and it did — the bullets were accurate, non-duplicative, and decision-shaped. None was
wrong. There were simply too many of them from the start.

### Root cause

The document tells the agent to write a bullet block and, at line 316, permits skipping it only for
"a single-line change (e.g. typo fix, version bump)". That makes bullets the default for anything
substantial, and sets the bar for removing one at the maintainer's request rather than before it.

The critique already asks whether a simpler message exists, but it asks that as a question during a
single pass. In practice the agent answered it by defending the draft it had just written. There is no
moment where the agent deletes its own bullets and reads what is left.

The default matters more than the rule. An agent that starts from "what does the reader need" and adds
bullets reaches a shorter message than one that starts from "what is true about this change" and adds
justifications.

### Proposed change

Try the subject alone first, and treat every bullet as needing a specific reason to exist. Add a final
pass that is mechanical rather than rhetorical: delete each bullet in turn, read the message, and keep
only those whose absence a reader would notice.

Broaden the skip condition from "single-line change" to any change whose subject states the whole
outcome.

### Applied

`SKILL.md` now says to draft the subject first and add bullets only against a named reader question,
with the delete-and-reread test as a required final pass. The skip condition is no longer tied to
change size.

### Detection note

Caught by the maintainer across four consecutive turns in one message. The lint passed every draft,
and every individual critique pass rated the bullets as sound. Only the reader's willingness to keep
deleting them exposed that they should never have been written.

## D-14 — A subject that named a broader subject of study than the change

**Severity:** Medium. The message is accurate about the change and misleading about its scope.

### What happened

The subject for a documentation consolidation read:

```
docs(skills): the rules for packaging a design live with the skill
```

The maintainer's correction: the main line should clarify that *design is part of a fixture*. The
revised subject was `docs(skills): the rules for a fixture's design live with the skill`.

Nothing about the sentence was inaccurate. The change genuinely concerned how a design is packaged,
and the skill genuinely now holds those rules. But read cold, "packaging a design" invites the reader
to assume the subject is design as a discipline — colour, typography, layout — when the actual subject
of study is the *design half of a reference package*. A reader carrying that assumption forward would
consult the skill for guidance it does not give.

### Root cause

The checks ask whether the subject is concrete, stands alone, and is supported by the bullets. None of
those catch a phrase that is true but under-scoped. Accuracy is not the same as scope: a message can
describe a subset of a topic in language that names the whole topic, and every existing check passes.

D-3 asks whether a word means what it ordinarily means. This is the neighbouring failure — a *phrase*
whose ordinary reading is broader than the thing being described. "Packaging a design" is ordinary
English for something wider than "packaging a fixture's design".

### Proposed change

Add a scope check: name the subject of study, then ask whether a reader could reasonably widen it to
something this change does not cover. The fix is a possessive or a preposition, not a longer sentence.

### Applied

Added to the critique's first question in `SKILL.md`, where scope is judged, and to the checklist.

### Detection note

Caught by the maintainer immediately after approving a near-identical subject one turn earlier. The
draft had already passed the critique, the lint, and a bullet-removal pass. It took someone asking
"what does this cover?" to expose it — which is the same detection route as D-13, and the reason both
notes say the same thing about mechanical checks.
