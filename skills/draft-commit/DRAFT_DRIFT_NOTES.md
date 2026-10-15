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

## D-15 — A limit the author knows and the message does not say

**Severity:** Medium-high. The message is accurate about everything it says, and the reader is misled
by what it leaves out.

### What happened

A change that renders session code into generated applications drafted its bullets as: a module could
not be given a database without failing the checks; the session code now ships with the rest of the
platform code; two generated notes no longer claim there is no authentication.

All three were true. None said that the code arrives **unused**, that the application still owns its
accounts table, and that the first sign-in fails until that migration is written — so the message read
as "sign-in now works in generated applications", which is the belief the missing sentence exists to
prevent. A reader who took the subject at face value would have handed the change to someone expecting
a working login.

The revised bullet says it in one clause: *the session code now ships in new applications unused; the
application still owns its accounts table, and without that migration the first sign-in fails*.

### Root cause

The limit lives in the evidence record — the spike's record of what was observed, and the decision
entry — and not in the staged diff. The diff's own tests demonstrate the new capability working, so a
draft written from the diff reads "it works now", and the draft had no reason to look further afield.

Nothing in the critique asks what the diff *cannot* show. Every existing check asks whether a claim in
the message is true; none asks whether a true message has been made misleading by an omission, because
the omission is not in the message to be checked.

### Proposed change

Add to the critique's third question an explicit step: re-read whatever record states what the
capability does **not** yet do, and check each bullet against it. The question already exists — *am I
holding back something only I can notice?* — but it is phrased around the diff, so a limit known only
from a spike or a decision entry never triggers it.

The useful discipline: before presenting, name the strongest assumption a reader would carry away from
the subject alone, then check whether any bullet contradicts or qualifies it. If the subject invites
"this now works", a bullet has to say where it does not yet.

### Applied

`SKILL.md` Step 3.5 item 3 now names the evidence record as the place to look, and the Quality Checklist
carries the "strongest assumption" question.

### Detection note

Found during self-critique, not by the lint, the checks, or the human — but only because the same
session had just written the spike record and the design. The failure mode is therefore *recency
dependent*: a change that was itself spiked this session is most likely to have its limit dropped from
its own commit message, because the author has the evidence fresh and the diff silent. A change written
months after its spike is more likely to over-report limits, from memory.

## D-16 — A subject shortened by coinage, and bullets pitched below it

**Severity:** High for the reader, invisible to every existing check. The subject took four attempts
to get right, and every wrong one was shorter than the right one.

### What happened

A change that renders session support into generated applications, and fixes two architecture checks,
took four subjects and eleven bullets before the human approved the wording:

| Attempt | Why it failed |
|---|---|
| "a generated app can admit an administrator **from local credentials**" | reads as *stored on this machine*, not *checked by the application* |
| "...a generated app can **now ship the session code** an administrator sign-in needs" | names the medium; *session code* is a phrase nothing in the project used and invites *a credential value* |
| bullets naming the credential check, the outside-provider decision, the corrected notes | true, verified, and too fine-grained to earn a line |
| subject describing rendering, bullet describing an architecture check | the bullet could not be worded into the subject at all |

The first two failures were caught by the human asking what a word meant. The third, by "bullets are
too detailed". The fourth, by "you have to rethink the bullets" — after which the real cause turned out
to be that the commit held two unrelated changes.

### Root cause

**Treating brevity as a goal.** Every wrong subject was shorter than the right one, and each was
produced by compressing a claim until it fit a shape rather than by choosing the clearest wording. The
qualifier that made the compressed phrase wrong is exactly the part compression removes.

**And pitching bullets below the subject's altitude.** The failing bullets were about configuration and
about documentation that had been corrected — real changes, accurately described, verified, and
invisible to a reader asking what they can now do. Nothing in the existing checks separates "true and
relevant" from "true and worth a line"; every one of them asks about truth, duplication, or legibility,
and a well-phrased fine-grained bullet passes all three.

The existing coinage check (D-3) does not catch this either. It looks for terms **borrowed from the
project's own vocabulary** — *island*, *replay*, *admission* — where the failure here was terms
**invented while shortening**, which is the opposite direction: the project never used them, and that
is precisely why nobody could read them.

### Proposed change

Two additions to the critique, both in `SKILL.md`:

1. In the main-line check: **name what the tool now does, never what was written**, with the medium list
   (*code*, *source*, *content*, *files*) called out; and **do not shorten a subject by inventing a
   phrase**, with the read-it-aloud test as the mechanism.
2. In the contribution check: **bullets sit at the subject's altitude** — the test is whether the bullet
   changes what somebody *does*, as against what they read or how a thing is configured.

Plus the remedy for the fourth failure, added to the subject-accuracy check: **when no wording makes a
bullet connect to the subject, the commit holds two changes** — split it. Each is a message that reads
well and cannot be attached to anything.

Three checklist questions carry them mechanically.

### Applied

`SKILL.md` Step 3.5 items 1, 2 and 7, and five new Quality Checklist questions.

### Detection note

Four rounds of human correction on one message, and the lint never objected to any of them — every
draft passed clean or passed with a single word-count warning. The reader was doing what no check here
does: asking what a word meant, asking whether the bullets were too detailed, and asking whether the
thing was two changes. Note the shape of the correction: each round arrived as a *question* rather than
an instruction ("what exactly is a session code?", "what do you mean by local credentials?"). That is
the form to expect when a check is missing — the reader is probing the message, not rewriting it, and
the answer is almost always that the wording was defending against a misreading that turned out to be
correct.

## D-17 — The message was reviewed; the change was not

**Severity:** High. Nothing in the ritual asked a question about the change itself.

### The reader-facing failure

A passive reader of that commit would conclude the one-database arrangement is now *enforced*. It is
not: nothing in the change stops the newly permitted file from being handed a **second** database. The
message would have described a clean fix and left the reader holding a guarantee it does not provide.

That is the same failure as D-15 — a limit the author knows and the message does not say — reached from
the other end. D-15 was caught by looking for what the message left out; this one is caught by asking
what the message *implies*, which requires knowing what the change does not do.

### What happened

A change that widens what the architecture checker permits was taken through four rounds of message
review. Each round was about wording: a coined phrase in the subject, bullets pitched below the subject,
a project term used as if it were plain English, a clause asserting more than was checked. The message
improved and was ready to commit.

Nobody had asked what the change now *permits*. Answering that for the first time produced the finding
the commit should have carried from the start: nothing stops the newly permitted file from being handed
a **second database**. The one-database discipline is a convention this change does not enforce and does
not claim to — a residual risk that had to be written down rather than discovered later.

The same pass produced the check that proved the widening stopped where intended: three pre-existing
tests already pinned the old limits, and the change added four more. That evidence existed and had never
been gathered, because no step asked for it.

### A second failure, same pass

The guardrail tests were run from the repository root. Every one of the eight "failed" — including four
that had passed minutes earlier. The invocation was wrong, not the code: the path is not a package from
that directory. Re-run from the module, all eight passed.

This is the same false-green shape as the CI defect found in the same session, and it is the natural
failure of a verification step run in a hurry: **a wholesale failure is more likely a wrong command
than a wrong change**, and the instinct to report the failure first is backwards.

### Root cause

Every existing step takes the change as given. The lint checks the message. The critique checks whether
the message describes the change. The checklist asks whether claims are supported. None of them asks
whether the change is sound, has a bounded blast radius, has its guardrails pinned, or carries a risk
the reader should know about.

The vocabulary hid it too. "Commit review" reads as reviewing the *message* — the artefact the ritual
actually produces — so an agent running the ritual diligently reviews the message well and never the
change.

### Proposed change

A new step, 3.6, **Review the change, not just the message**, run before presenting: name the problem
and who was hurt; name the rejected alternative; state the blast radius; name the guardrail tests and
run them; state the residual risk; confirm it is the smallest change. With the verification corollary —
a wholesale test failure is a wrong command until proven otherwise.

Two checklist questions carry it mechanically.

### Applied

`SKILL.md` Step 3.6, and two Quality Checklist questions.

### Detection note

The maintainer asked for the review to be run the way a reviewer runs one — *"as a CTO, you know what to
ask if presented with the commit during commit reviews"* — and the residual risk appeared immediately.
That is the route to expect: the gap is in the ritual's framing, not in anyone's diligence, so
supplying the reviewer's stance surfaces it in one turn. A ritual step is the durable fix; asking to be
reviewed this way is the workaround until the step exists.

## D-18 — One staging command, one commit, whatever the tree happened to contain

**Severity:** Medium-high. Produces a commit with no main line, which forces a vague subject and a
bulleted list in place of an argument.

### The reader-facing failure

A commit built from a whole working tree reads as an inventory. The reader gets "updated several things"
where they needed one sentence saying what is now possible, and they cannot tell which change they could
revert alone if it caused a problem.

### What happened

Six unrelated concerns sat in the framework tree at once: a rendering change, a review-rule change, a
skills document, a design fixture with its PSDs, a moved diagram, and a proposal. `git add .` put all six
in front of one draft, and the first subject could only be about a third of them.

The first attempt at fixing it over-corrected: the two code changes were split again on the grounds that
one bullet could not be worded into the subject — splitting a single file's diff by hunks, to serve the
message rather than the reader. The maintainer rejected that: *"i dont get why you need to separate."*
They were right. The two changes were one story, found while fixing one module, and splitting them bought
a tidier message at the cost of a second commit to read.

So the failure was not "staged too much". It was **no decision about grouping at all** — neither
grouping nor deliberately choosing fewer.

### Root cause

`git add .` is presented as the step, so staging is treated as mechanical and grouping as absent. The
skill then evaluates one message as though one commit were given, and its checks — subject, bullets,
altitude — all operate inside that assumption. Nothing asks what the commits *are*.

Meanwhile the correction to the over-split was just as unavailable: nothing recorded that splitting
carries a cost, so the reflex when a subject will not cover a bullet is to split.

### Proposed change

Replace Step 1's staging with **grouping**. Read the working tree, propose the smallest set of commits
that covers it, present the grouping with a one-line subject each, and get approval before drafting.
Then give the judgment an explicit default: **fewer commits**, because a commit per concern costs the
reviewer, and splitting to make a subject fit is splitting for the message's sake.

Recorded with the criteria that decide it — one subject that honestly summarizes, independently
revertible, leaves the repository working — and with what must never be separated, chiefly a fix from
the test that pins it.

### Applied

`SKILL.md` Step 1, rewritten as grouping-then-staging, and two Quality Checklist questions.

### Detection note

Raised by the maintainer as a design point rather than a complaint about a message — *"agent should be
smart to batch commits if necessary"* — after watching the same working tree go through one oversized
commit, one over-split, and two reasonable ones. The pattern worth noticing: both errors came from the
same silence. A step that says "decide the grouping" prevents the first; the note that fewer is the
default prevents the second.

## D-19 — The guidance pushed toward plainer words, and the right answer was the platform's

**Severity:** Medium-high. Produces vaguer messages that a practitioner has to work harder to read, and
costs several rounds of correction to notice.

### The reader-facing failure

A subject written in the project's own vocabulary — or in a plausible invention — leaves a reader who
works in the ecosystem unable to place the change at all. "A new application can now sign in an
administrator" was fine; the attempts that followed it were not. **A module can now be given the
shared database** is unreadable without knowing what a module is here. **Ships the session code** is
unreadable without knowing what "session code" means, and means something else entirely to anyone who
has read a compiler. The final subject — *vendored or linked* — is understood immediately by any Go
developer, because both words are terms that ecosystem already uses.

### What happened

The fine-tuning converged on this by accident, through a sequence of corrections: *local credentials* →
readable as "stored on this machine"; *own tables* → readable as a database per module; *session code* →
a phrase nothing in the project used; *either layout* → a project word meaning nothing in Go; *inlined* →
function inlining. Each was rejected by the same reader asking what a word meant.

The last step was the informative one. Asked whether "inlined" and "referenced" were the right terms,
the answer was that the platform already had exact words: **vendored** for copying dependency source in,
and **linked** for the other. The subject got shorter and more precise at the same time.

### Root cause

The existing guidance says *"the plain word is nearly always available"*, and ranks plain English above
a project's own term. Applied here it would have rewritten *vendored* as *copied in* — vaguer, and
wrong for the reader. The guidance is sound about **project coinages** and unsound as a general
preference: it never asked who the reader is.

The reader is not a bystander. They are a practitioner of the platform the change lands in, and that
audience already owns a vocabulary. Plain English is the fallback for concepts the platform has no word
for — not the default that outranks everything.

### Proposed change

Amend the coined-terms check with an order of preference — **the platform's established term, then the
project's own word where it is also a real interface (a flag, a command), then plain words only where the
platform has none** — and name the two failure modes that disguise themselves as plainness: a word that
is ordinary in the project's records and opaque in the ecosystem (*layout*), and a plausible invention
that collides with an unrelated established meaning (*inlined*).

Carried into the checklist as an alternative to the plain-English question, not instead of it: the first
still guards against project coinage, the new one guards against needless paraphrase.

### Applied

`SKILL.md` Step 3.5, item 1, and one added Quality Checklist question.

### Detection note

Not a complaint about any single message — it arrived as a design observation after a session in which
the wording was corrected six times. That is the tell: when the same reader keeps asking *what does this
word mean*, the question is not the word in the message but the **audience the guidance assumes**. The
corrections were individually about vocabulary and collectively about who is reading.

## D-20 — The critique was written by the person the message defends

**Severity:** High. Every step before the approval gate asks a question the author can answer from
memory, which is why defects survive all of them and reach the human.

### The reader-facing failure

A commit that adds a review step, a grouping step, and a set of wording rules presented a message whose
first two bullets read *"a change's blast radius, rejected alternative, and residual risk get named
before a draft is presented"* and *"staging becomes a grouping decision proposed for approval"*. Both
were accurate. Both were **contents** — a reader could reconstruct the new steps from them and learn
nothing about the failures those steps exist to prevent. The third bullet asked for a rule, in the same
register. Meanwhile the subject carried *"the commit boundaries"*, the vaguest phrase in a message whose
whole argument is that vague phrases mislead readers.

None of this was visible to the checks already in place. Every question in the critique is answerable
from inside the session that produced the change, and every question was being answered from inside it.

### What happened

The draft had already been through the critique, the lint, and a bullet-removal pass, and was presented.
The human asked for it to be **reviewed as a CTO**. That stance — a reader with the authority to send
the draft back, no access to the session, and no clarifying questions available — produced three
objections in one pass: two bullets described the checklist instead of the situation, the subject's
weakest phrase was still there, and the one-commit question had not been examined at all.

Every one of those was available earlier. None was found earlier.

### Root cause

**The critic and the criticized are the same party.** Step 3.5 asks whether the message describes the
right thing and Step 3.6 asks whether the change is sound; both are asked by the author, holding the
diff, and both are answered by recall. Recall is where the defects live: the author knows what "the
commit boundaries" means, so it reads as precise; the author knows what each new step contains, so a
bullet reciting a step reads as informative.

No step adopted **the reader's position**. The checks vary the question — is it a decision, does it sit
at the subject's altitude, is the change sound — and none of them varies the *stance*. A question asked
from the author's seat gets an author-shaped answer whatever the question is.

There is also a mechanism the notes already named and the ritual never used. D-16 recorded that every
correction arrived as a **question** rather than an instruction: *what does this word mean*, *what does
this cover*, *is this enforced*. A reviewer's question is a defect report. The ritual had checks for
truth and legibility but nothing that asked the agent to notice the questions it would have to ask.

### Proposed change

A mandatory step, **3.7 — Review the draft as the person who receives it**, run before presenting and
not waited to be asked. The stance is defined, not suggested: a reviewer with the authority to send the
draft back, reading cold, with no access to the session and no clarifying questions available except
by writing *what does this word mean?* Five questions in order — what do I wrongly believe is true,
what does this permit that it should not, what would surprise me as missing, what would I ask the
author, and would I merge this or send it back — with a required verdict, since a pass that ends
without one did not happen.

Its output is presented the way Step 3.5 requires its critique: the objections and the revised draft
together, so the human sees what the pass caught rather than a message that appears already perfect.

### Applied

`SKILL.md` Step 3.7, three Quality Checklist questions, and a line in the protocol validation that
fails if the pass was skipped.

### Detection note

The maintainer asked for the stance by name, and had to ask for it **after** a critique the agent had
already run unprompted — the second request in a session in which the agent believed it had already
reviewed the message. That gap between what the agent believed it had done and what the reader wanted
is the failure: the agent was reviewing, and reviewing is not the same act as being reviewed. When a
maintainer supplies a *stance* rather than a finding — "as a CTO", "as a reviewer would", "the way I'd
present it" — the missing thing is not diligence. It is a step, and the workaround will keep being
needed until the step exists.
