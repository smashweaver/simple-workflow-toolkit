---
name: "draft-commit"
description: Draft-and-Approve commit ritual with a lint gate. Drop into any git repo. Use when writing commit messages or creating commits. Produces impact-focused, no-structural-noise commit messages via a human-in-the-loop approval step. No dependencies on task managers, state machines, or workflow orchestrators.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# draft-commit — Portable Commit Ritual

Impact-focused commit messages make code history readable and maintainable. This skill enforces a Draft-and-Approve workflow with a lint gate. It is self-contained: no task manager, no state machine, no pre-commit hook installed by the skill. Drop the `skills/draft-commit/` directory into any git repo and it works.

---

## Before drafting

Verify the skill and lint script are present, inspect the staged diff for WIP markers or debug statements, and check that no stale `commit.diff` or `commit.draft` remains. Run the reviewer pass later, after the draft exists.

Read the owning task/issue and the latest owner direction before treating the diff as the whole story. Establish the change in context: what behavior or command already existed, what this change alters, and what remains unchanged. Confirm command or API names against current source or documentation. Draft the subject for that before/after difference; do not make a fix to an existing capability sound like the capability itself is new, or let a narrow correction imply a broader workflow changed. If there is no task contract or owner direction, say so and use the repository's current product records.

> [!CAUTION]
> **Keep structural noise out of the message.** Bullets describe outcomes, not paths, extensions, or internal refactoring. The lint rejects structural noise in bullets and warns about paths in the subject.

---

## Diff-First Workflow

**Draft-and-Approve**: All commits go through a formal draft phase for human review. The skill never auto-commits — the human always says "apply."

Two temporary files are used (both should be in your `.gitignore`):
- **`commit.diff`** — the staged diff exported from git
- **`commit.draft`** — the agent-drafted commit message, ready for review

### Step 0 — Preview on unstaged files (optional)

```bash
bash skills/draft-commit/scripts/draft-commit.sh --preview
bash skills/draft-commit/scripts/draft-commit.sh --preview --draft "type(scope): concrete outcome"
```

Preview gets the diff on unstaged files and applies the draft-commit logic to it: status plus unstaged diff stats, protocol validation on the unstaged diff (WIP markers, debug statements, repo hygiene), then the full unstaged diff itself for drafting, and, with `--draft`, an in-memory lint of the message. It never stages anything and never writes `commit.diff` or `commit.draft`.

### Step 1 — Group the changes into commits, then stage each one

```bash
git status --porcelain     # the working tree, including untracked files
```

**Do not `git add .` and draft whatever lands.** A working tree accumulates unrelated work — a fix, a
documentation update, a design fixture, a moved file — and one commit containing all of it has no main
line, so its subject can only be vague and its bullets can only be a list of things. Group first.

Read the tree and propose the smallest set of commits that covers it. **Present the grouping and get
approval before drafting anything** — it is a decision about the history, and it is cheap to change now
and expensive once messages exist. For each proposed commit, name its files and the one-line subject it
would carry.

**What makes a coherent commit:**

- One subject can honestly summarize it. If you cannot write that sentence, it is two commits.
- It is independently revertible. A reader can drop one commit without stranding the others.
- It leaves the repository working, or explains why an intermediate state does not.

**What rides together:**

- A change and the documentation or evidence that only that change produced.
- A file's new home and the change that put it there — unless the move is the whole point, as a pure
  relocation whose review value is the rename itself.
- A fix and the test that pins it. Never split these; the test is what makes the fix a claim.

**Where the judgment actually falls — default to fewer.** Splitting costs the reviewer a commit per
concern, and a commit that exists only because the work happened in one session is noise. Split when a
subject genuinely cannot cover both halves; do not split merely to make each commit smaller, and do not
split a single concern across several commits because its parts happen to sit in different files. Two
changes discovered while fixing one module are often one story — say so, and let the subject carry it.

Then stage and commit one group at a time:

```bash
git add <paths for this commit>
git status --short         # confirm this group, and nothing else, is staged
```

To unstage a specific file:
```bash
git reset HEAD <file>
```

A file that belongs to two groups is a signal that one of the groups is not the change you thought it
was. Go back to the grouping rather than staging it twice.

### Step 2 — Capture the staged diff

```bash
git diff --cached > commit.diff
```

### Step 3 — Generate a validated commit draft

**Establish purpose first.** Read the repository's own statement of purpose (README, PRD, brief,
issue) and write one sentence naming what this change is evidence of, enables, or settles. Every
bullet and the subject are measured against that sentence, not against the diff. A person reading
`git log` should not have to open the README to learn why the code matters.

Reconcile that purpose with the task's before/after context above. In particular, distinguish an
existing command or capability from the behavior this change corrects, extends, or removes. The subject
names the changed behavior, not an existing command as though this commit introduced it.

Start with the subject: state the concrete outcome on its own. Add a bullet only when it supplies
important information the subject leaves out, such as a limit, cost, or choice. For example, after
`feat(map): let people choose a starting point`, `* People can drop a pin or enter coordinates`
answers *which choices are available?* A bullet about where the chooser link moved usually just
narrates the interface. If the subject states the whole outcome, it is the complete message.

Avoid vague subjects such as `clarify requirements`. Verbs like "update,"
"improve," or "clarify" are useful only when the subject states the concrete
change. For example, bullets establishing a required CLI and proposal conventions
support `chore(workflow): define CLI requirements and proposal conventions`.

Run the skill with your draft message. The skill runs it through the lint gate and saves the validated version to `commit.draft`. The lint checks syntax; the agent must also check that the subject accurately summarizes the bullets.

```bash
# Standard usage: skill generates the draft from your message
bash skills/draft-commit/scripts/draft-commit.sh --draft "type(scope): concrete outcome"

# Add bullets only for important facts the subject leaves out, such as a limit, cost, or choice.

# With an optional reference (e.g. for issue trackers)
bash skills/draft-commit/scripts/draft-commit.sh --draft "type(scope): summary

* bullet" --ref "Fixes #42"

# With a pre-written message file
bash skills/draft-commit/scripts/draft-commit.sh --draft "$(cat /tmp/msg.txt)"
```

The skill will:
1. Run the lint gate against your draft.
2. If lint passes, save the draft to `commit.draft` and print it for review.
3. If lint fails, print the errors and exit non-zero. Self-correct and retry (max 3 attempts).

> ⚠️ **The skill MUST NOT execute any `git commit` command at this stage.** Approval is the human's call.

### Step 3.5 — Critique the draft before presenting it

The lint gate checks that a message is well-formed. It cannot check that a well-formed message
describes the right thing, and the most common failure is exactly that: accurate, grammatical
prose about the change's behavior rather than its contribution. So the agent critiques its own
draft and revises it **before** the human reads it.

**Surface what you are assuming.** The checks below all test a draft you believe is sound, which is
the trap: *"the subject is concrete"*, *"the bullets are fine"*, *"this is what the change does"* —
each of those has passed every check here and each has been wrong. Name the assumptions out loud
before checking anything, and if one is wrong the rest of the pass was theatre.

These three questions are adapted from `swt:think`, whose first two sections are general reasoning
guidelines rather than part of that tool's task workflow. They are reproduced here so the discipline
travels with the ritual that needs it, rather than depending on a skill in another repository.

Ask three questions, and answer them in the critique rather than in your head:

- **What am I assuming here that I have not verified?** Unverified assumptions are what every check
  in this file is designed to catch, and they are also what lets a bad draft keep passing.
- **Is there a simpler message?** A draft that has been revised three times is usually trying to carry
  two arguments in one body. Cut to the fewest bullets that each earn their place — a bullet the
  reader could delete without losing anything is a bullet that was costing them.
- **Am I holding back something only I can notice?** Check the diff and any evidence or decision record
  that states what the change does not yet do. If a known limit would change what a reader expects, carry
  it into the draft. Raising it costs one sentence; being caught omitting it costs the whole message.

**Surface the revision, do not just perform it.** When you revise, show what changed and why. A
draft that appears already-perfect after three silent passes teaches the human nothing about where
the traps are, and the next one gets the same treatment. If the human asked for a critique and you
found nothing, say so briefly — do not manufacture objections to look thorough.

Critique against the purpose sentence from Step 3. Work in order — the first check decides whether
the others can land.

1. **Can you follow the main line?** State the change back as plain behavior in one sentence, the
   way you would to a colleague who has not opened the diff. Then check the **scope** of what you named:
   could a reader reasonably widen "packaging a design" into design as a discipline, when the actual
   subject of study is one part of something larger? A message can be accurate about its change and
   still misname its subject, and no accuracy check catches that. The fix is usually a possessive or a
   preposition — *a fixture's design*, not *a design* — rather than a longer sentence. If you cannot do that with ordinary
   words, the subject is aimed at the repository rather than at a reader, and that is the defect. A
   reader who understands every word and still has to work out what happened has not been told the
   main line.

   **No coined terms in a subject.** Flag every word that this project invented, defined in its own
   record, or uses to mean something other than its ordinary meaning — *scripted*, *island*,
   *enhanced*, *native*, *shape*, *replay*, *admission* are all common coinages in software. Each is
   legible to the team and opaque outside it, and the reader pays for it.

   A plain word is often available: **a request made by JavaScript** for "scripted", **part of a page**
   for "island", **a size limit** for "bound". Use the platform's established term when it is more
   precise for the intended reader; when no such term exists, prefer ordinary words over project coinage.

   A coined term earns a place in a subject only when it names a genuine load-bearing concept with no
   plainer synonym. Even then, spell it out in the first bullet.

   **Prefer the platform's word over a plainer one.** The reader is a practitioner of the ecosystem the
   change lands in, not a bystander reading English. They know what `go mod vendor` does, what a module
   is, what a migration is — and for those, the ecosystem's word is *more* precise than plain English,
   not less. So the order of preference is: the platform's established term, then the project's own word
   where it is also a real interface the reader will meet (a flag, a command), then plain words only
   where the platform has no term at all.

   Two failure modes that look like plainness:

   - **A word can be ordinary here and opaque in the ecosystem.** *Layout* is fine in a project's own
     records and means nothing to a Go developer reading the history, because Go has no such concept
     under that name. Ask what a practitioner of *this* platform would call it.
   - **A plausible invention can collide with an unrelated established meaning.** *Inlined* reads like a
     reasonable gloss on "copied the source in" and means function inlining to every compiler engineer.
     Where the platform already has a word for the act, the coinage is not just vaguer, it is wrong.

   And where the project's word *is* the tool's own — a flag, a command — prefer it, so the history and
   the interface agree and a reader can grep from one to the other.

   **Name what the tool now does, never what was written.** A subject that reaches for the medium —
   *code*, *source*, *content*, *files* — describes the artifact rather than the change, and the reader
   has no reason to care in what form the change arrived. "Ships the session code an application needs"
   says the same as "can now sign in an administrator" with three extra words and one chance to
   misread: *code* invites the reader to picture a snippet, when what arrived is a capability. Say what
   the tool, the application, or the user can now do. If the change really is only about a file
   existing, then the honest subject is about what that file makes possible, not about the file.

   **Do not shorten a subject by inventing a phrase.** Brevity is not a goal, and every compression
   taken to protect it tends to cost a qualifier. Three real attempts at one subject produced "local
   credentials" (readable as *stored on this machine* rather than *checked by the application*),
   "own tables" (readable as a database per module rather than tables in one shared database), and
   "session code" (a phrase nothing in the project used, readable as a credential value). All three
   were shorter, all three were wrong, and each was caught by a reader asking what a word meant —
   which is the test to run before presenting: **say each word of the subject aloud to someone who has
   not opened the diff, and notice the moment you have to explain it.**

   When the precise wording will not fit, the fix is the *bullet*, not the shorter word. Precision that
   the headline cannot carry belongs one line down, where there is room for it.
2. **Contribution, not contents.** Would someone reading only this message learn what the change
   makes possible, or merely what it contains? A message a reader could use to reconstruct the
   implementation is describing contents.

   **Bullets sit at the subject's altitude, not below it.** A bullet can be true, relevant, and
   verified, and still be too fine-grained to earn a line: facts about configuration, about the shape
   of an implementation, or about documentation corrected along the way are all real and all invisible
   at the altitude of "what can this now do". Ask of each bullet: does this change what somebody
   *does*? If the honest answer is "it changes what somebody reads", it belongs in the evidence record
   or the design document, and the reader meets it the moment they open the file. A bullet about where a
   control moved, what a label says, or how a panel is arranged is answered by opening the app; keep it
   only if it still matters to a reader who cannot see the interface. The discipline is the delete-in-turn
   pass, run earlier and more literally than usual: most drafted bullets are true-but-fine and cost the
   reader a line they would have spent better elsewhere.
3. **Duplication.** Does any bullet restate the subject, or two bullets argue the same point?
   Merge them and spend the freed slot on something the reader does not yet know.
4. **Evidence in the wrong place.** A bullet reciting test results belongs in the project's
   evidence record, not in history. History says what was settled.
5. **Missing reassurance.** What would the reader's first question be — "does this change what I
   have?", "what does it cost?", "is it on by default?" — and does the message answer it? If the
   change is opt-in, say so. If it gives something up, say what.
6. **Bullet legibility.** Read each bullet on its own and check six things:
   - **Situation, not mechanism.** Does the bullet describe *what was happening and what it cost*,
     or *how the code works*? A bullet is history, and history is about the world the change happened
     in. "Ran inside the lock every other request needs" is a description of a mutex wearing ordinary
     words; "ran on whichever unlucky request arrived next, so everyone else waited while it tidied"
     is the same fact as something that happened to people. The test: could a reader who does not
     write this code still find the bullet true and useful?
   - **Aim at where it bites.** A bullet about a check the change adds should name the moment the
     check earns its keep, not the fact that the check exists. "Rewording a message reports how many
     commits change hash" describes a rule; "rewording a commit further back reports how many
     commits change hash" names the case where someone is actually hurt by not knowing. Same fact,
     different reader: the first is a summary of the tooling, the second is something a person
     needed once. Take any bullet whose subject is a guardrail and ask which mistake it prevents —
     if the answer is a situation, that situation belongs in the bullet.
   - **One clause before the verb.** If three modifiers stack up before the main verb, the point is
     at the end of the sentence where nobody reads. Put the verb first.
   - **The term rule applies to bullets too.** A subject cleaned of coined terms while its bullets
     keep "shape", "fragment", and "replay" has only been half fixed — the reader still pays, and
     now pays again after reading on. Same substitution: a term a reader must look up belongs in the
     diff, not the history.
   - **No invented plain-sounding name for a missing thing.** Do not coin a friendly phrase like
     "page-part lookup" for an absent mechanism. That sends a reader looking for something that was
     never built. Name the real mechanism, or describe the absence in ordinary words ("nothing looks
     up which part of a page was asked for").
   - **Under 30 words.** Longer than that and it is a paragraph that should be split or cut. A bullet
     carrying an argument about *why* usually wants the argument kept and the explanation dropped.

   **The six sub-checks above are necessary and not sufficient.** A bullet can contain no
   coined terms, invent no name, sit under thirty words, and reach its verb in one clause — and still
   be a description of internals that only its author finds informative. Situation-first is the check
   that catches those.
7. **Subject accuracy, in both directions.** Does the subject still summarize the revised bullets, and
   does it stand alone? Then ask the inverse, which is the one that fails silently: **do the bullets
   still support the subject?** A message with an accurate subject and individually excellent bullets
   that are all about something else is still a message about something else, and every legibility check
   above will have passed. The test: if the subject's own key noun appears in no bullet, the bullets
   have drifted. The pull is always toward the more articulate topic — safety machinery and developer
   experience make better sentences than a design decision does, so the bullets drift toward what is
   easiest to say well and the subject's actual claim goes unrepresented.

   **When no wording makes them connect, the commit holds two changes.** A subject that describes one
   thing and bullets that describe another is not a wording problem, and rewriting will not fix it —
   each rewrite makes the bullets shorter while the mismatch stays. The remedy is to split: two
   changes that are independently reviewable and independently revertible belong in two commits, each
   with a subject that summarizes its own bullets. This failure is easy to miss because the bullets can
   individually be excellent, and because the temptation is to keep polishing instead of asking whether
   the staging was honest. The tell is a bullet the reader cannot connect to the subject no matter how
   it is worded — that bullet is evidence about the *commit*, not about the prose.
8. **Choice or expectation?** For each bullet, ask what would be different had we decided otherwise. If
   the answer is *nothing*, the bullet records how the language, framework or tool behaves rather than
   what this change did — and history records what was settled. Most available facts about a change are
   consequences that follow anyway, and they are the easiest to write because they are the most
   concrete. If adding "and this is surprising", or "which is not what the tool does by default", to
   the bullet would be false, it is an expectation. Cut it.
9. **Does the bullet assert only what was checked?** Claims of *shared*, *owned*, *per-application*,
   *isolated*, *identical* or *independent* describe a relationship, and a diff usually cannot show
   one: two identical files look like sharing, and the absence of a dependency appears as the absence
   of a line. Confirm each relationship, and ask what a reader would *do* differently on the strength of
   it. If nothing, it is decoration. A count in the message is counted, not remembered — if the number
   is not in front of you, count it. And a check that passes the first time has not been shown to have
   teeth: before believing it, make a second run in which the thing you expect to trip actually trips.
   Record the command and observed result accurately; distinguish what ran from what you infer it proves.

Items 8 and 9 are reading checks and cannot be mechanized. The lint cannot tell an expectation from a
decision, and cannot distinguish a verified relationship from an inferred one — the words are identical
either way. They are named steps precisely because nothing else will prompt them, which is how D-6
through D-9 all reached a human review of a finished-looking draft.

On (1): abstract and concrete are not opposites. A subject may name a settled decision, a boundary,
or a guarantee, and still be concrete — `fix(auth): a session that is revoked mid-request stops
being trusted` is concrete. What makes a subject vague is that its **subject of study** is the
decision rather than the behavior. `close the response-shape half that CSRF protection deferred`
names a chapter in the project's own record and leaves the reader to infer that a fragment response
now exists. Put the behavior in the subject; the decision it settles is a bullet, or belongs in the
commit body.

If a subject can only be understood by someone who already knows the project, that is the test for
this failure — and it is not the same test as (2).

The hardest part of (1) is that the writer cannot feel the problem. Whoever drafted the message holds
the whole diff in their head, so a subject that is opaque to a newcomer feels perfectly clear. Asking
"would this make sense to someone who has not read the diff?" is the only reliable way to find out,
and it has to be asked deliberately rather than assumed — the draft will always read well to its
author.

Present the critique alongside the revised draft, not instead of it. The human is entitled to see
what was wrong with the first attempt; that is the part that makes the message trustworthy over
time. One revision pass is the expectation — if the critique finds nothing, say so briefly and
move on rather than manufacturing objections.

Record any *systematic* failure here in [DRAFT_DRIFT_NOTES.md](DRAFT_DRIFT_NOTES.md), the same way
the existing entries were recorded: a real failure, its root cause, and the change that would
remove the cause. A one-off wording problem is not a note.

### Step 3.6 — Review the change, not just the message

Step 3.5 asks whether the message describes the right thing. It cannot ask whether the *change* is
sound, because the diff is taken as given. That gap is where the expensive mistakes live: a message can
be perfect about a change whose blast radius nobody examined.

**Anchor every question below in the reader, not in the reviewer.** A note written as "the agent failed
to ask about the blast radius" describes one session; a note written as "a reader of this commit would
conclude the arrangement is now enforced, and it is not" describes a failure that recurs. For each
question, the check is: *what would a passive reader wrongly come away believing if this went
unexamined?* Name that, and the question earns its place. Many of these turn out to be the same failure
as D-15 — a limit the author knows and the message does not say.

Run this before presenting, and answer from the diff and the repository — not from the intention that
produced the change. Six questions:

1. **What problem does this solve, and who was hurt?** Name the situation it was found in and who
   noticed. A change whose problem cannot be named is usually a change nobody needed.
2. **Why this approach rather than the obvious alternative?** Name the alternative and why it lost. An
   exemption that leaves the broad rule intact needs that argument; without it, the change looks like
   the rule quietly stopped applying.
3. **What is the blast radius?** What does this now permit that it should not? Answer it, do not
   gesture at it. If the honest answer is "nothing stops X", that is a residual risk and belongs in the
   message or the reviewer's attention — not in silence.
4. **Which guardrails are pinned by a test, and did you run them?** Name the tests that would fail if
   the change were wrong, then run them. A change that widens what is permitted needs at least one
   check that the widening stopped where it was meant to.
5. **What residual risk would you want on the record?** The limit this change does *not* address and
   does not claim to. One sentence, stated plainly.
6. **Is this the smallest change that settles the question?** If a smaller one would, the larger one is
   carrying risk for nothing.

**A command that fails wholesale should be re-checked before its output is believed.** A verification
run where *every* check fails is far more often a wrong invocation than a wrong change: a path that is
not a package, a filter matching nothing, an environment the runner does not have. Re-run it from
where it would actually run before concluding anything — and say which it was, because a false negative
here is the same shape as a false green.

### Step 3.7 — Review the draft as the person who receives it

**This step is not optional and does not wait to be asked.** The human should never be the first reader
to meet a finished-looking draft. Step 3.5 asks whether the message is well-formed and Step 3.6 asks
whether the change is sound; neither can ask the question that catches most of what actually reaches
a human review, because both are asked by the author, who is holding the diff and already knows what
every word means.

Adopt a different stance and hold it for the whole pass. **You are the reviewer the commit is presented
to — someone with the authority to send it back, reading the message cold, with no access to the
session that produced it.** Not a co-author being careful. Not a summarizer of the diff. A reader who
sees the message and the change and nothing else, and who will not ask you a clarifying question
except by writing *what does this word mean?*

That last constraint is the mechanism. A reviewer's correction arrives as a **question**, not an
instruction — "what does this commit cover?", "what exactly is a session code?", "is this enforced?" —
and a question is evidence that the message made them do the author's work. Run the pass looking for
the moment you would have to stop and ask.

Five questions, in this order:

1. **Reading only the message, what do I now believe is true that is not?** Name the strongest
   assumption the subject invites, then check whether any bullet qualifies it. This is where D-15 and
   D-17 live: a message can be flawless about a change whose limits nobody examined.
2. **What does this permit that it should not?** Answer it from the change, not from the subject. If
   the honest answer is "nothing stops X", that is a limit the message does not carry.
3. **What is in the change that I would be surprised to see missing?** Especially something true,
   verified, and too small to earn a bullet — the reader meets it when they open the diff, and the
   surprise is what they remember about your judgement.
4. **What would I ask the author?** Write the questions out, then decide whether each belongs in the
   message. A question answered by the interface itself—such as where a visible control moved—does not
   automatically earn a bullet. Keep that detail only if it matters to a reader who cannot see the
   interface.
5. **Would I merge this, or send it back?** Decide, and if back, name the one thing that has to change.
   A pass that ends with no verdict is a pass that did not happen.

**Then revise, and show what the pass caught.** The point is not to report that you reviewed — it is
that the reviewer stance finds objections the author's stance cannot. Present the objections and the
revised draft together, the same way Step 3.5 requires its critique. If the pass genuinely finds
nothing, say so in one line and present the draft; do not manufacture objections to look thorough.

**A reviewer is not an approver.** This pass produces a verdict you carry into the approval gate; it
never replaces the human's "apply". Nothing here runs `git commit`.

### Step 4 — Fine-tune

The user may edit `commit.draft` directly in their editor, or ask the agent to make specific changes. The skill itself does not run iteration; the agent does, in conversation with the user.

**Before revising a message whose commit already exists,** establish what the change costs. A message
for an uncommitted draft is free to change; a message for a committed one may rewrite history.

```sh
git log --oneline -3                        # is it the tip, or further back?
git log --oneline <sha>..HEAD | wc -l       # how many commits would change hash
git branch -r --contains <sha>              # has it reached a remote?
```

Report that blast radius as part of the proposal — not after the user has approved it. Rewriting a
local commit is routine; rewriting one already pushed changes what other clones hold and cannot be
undone by anyone who has fetched. Getting this check wrong means recommending a force-push as though
it were a reword, and walking it back afterwards.

For every revision:
1. Read the current `commit.draft`.
2. Re-analyze `commit.diff` for technical accuracy.
3. Update the draft in place.
4. Re-run the lint gate to confirm the new version still passes.

### Step 5 — Approval Gate (HARD STOP)

> 🚫 **The skill is STRICTLY FORBIDDEN from executing `git commit` unless the user gives explicit approval.**

After the draft is finalized, present this binary choice:

---
**Ready to commit?**
- **Apply** — run `git commit -F commit.draft`
- **Fine-tune** — edit `commit.draft` or tell me what to change
---

The user must say "apply" (or equivalent) before the commit runs.

### Step 6 — Commit (human-executed)

On explicit "apply" confirmation:

```bash
git commit -F commit.draft
```

If `--ref` was provided, the draft already includes the reference. No additional step needed.

### Step 7 — Cleanup

After the commit lands:
```bash
rm -f commit.diff commit.draft
```

> 🧹 **Always clean up**. The skill does not auto-clean; the agent or user does it after a successful commit.

---

## Format

A commit message may be just a subject. Add a bullet only when it supplies an important fact the
subject leaves out:

```
feat(map): let people choose a starting point

* People can drop a pin or enter coordinates
```

The bullet answers *which choices are available?* A detail about where the chooser link moved is
usually visible in the app and does not need a line in history. More generally, bullets can carry a
limit, cost, or decision that the subject cannot fit; do not add generic benefit, problem, or performance
bullets by default.

Most messages need no bullets. A subject that states the whole outcome is complete, and size is not the
test — a change spanning many files can still be fully described by its subject.

Before presenting, **delete each bullet in turn and read what remains.** Keep it only if removing the
fact would leave the reader with an important gap; if you cannot say what they would miss, it is costing
them a line.

This pass is separate from the critique and comes after it, because the critique asks whether a draft
is well-formed — and a padded draft is well-formed. Deleting your own bullets is the only reliable way
to find the ones you were defending rather than writing.

### Types

- `feat` — New feature or functionality
- `fix` — Bug fix
- `chore` — Minor cleanups, maintenance
- `refactor` — Code restructuring without behavior changes
- `test` — Test additions or modifications
- `docs` — Documentation changes
- `style` — Code style/formatting (no logic changes)
- `perf` — Performance improvements

### Scope

Use the most specific functional area affected. Prefer narrow scopes (`auth`, `routes`, `models`) over broad ones (`backend`, `frontend`).

---

## Quality Checklist

Use this as a final check before presenting the draft. Complete each check at the step it names;
change grouping is decided in Step 1, before drafting.

- [ ] Does the subject state the concrete outcome on its own? If there are bullets, do they support it without merely restating it?
- [ ] **Do the bullets support the subject?** If the subject's key noun appears in no bullet, they are about something else.
- [ ] For each bullet: **is it a decision?** If nothing would differ had we decided otherwise, it records expected behaviour — cut it.
- [ ] Does any bullet assert a relationship (*shared*, *owned*, *per-application*, *isolated*, *identical*, *independent*) I actually verified? Would a reader act differently on it?
- [ ] Is every count in the message one I counted rather than remembered?
- [ ] Can a reader state what changed, in plain behavior, without an internal term or a chapter name?
- [ ] Does the subject avoid project coinage and use the platform's established term when it is more precise, otherwise ordinary English?
- [ ] For each bullet about a guardrail: does it name the mistake it prevents, rather than the rule's existence?
- [ ] Does each bullet reach its verb within one clause, and stay under 30 words?
- [ ] Does each bullet describe what happened and what it cost, rather than how the code works?
- [ ] Do the bullets avoid coined terms too, and name absent mechanisms by their real name or in plain words?
- [ ] Does the subject say what the change **contributes** to this repository, not only what it contains? If the repository exists to prove, evaluate, or demonstrate something, does the subject say what this change shows, verifies, or enables?
- [ ] Could a reader use these bullets to reconstruct the implementation? If so, they describe contents rather than contribution.
- [ ] Would someone understand the **impact** without knowing implementation?
- [ ] Could a reader widen what the subject names into something this change does not cover?
- [ ] Does the subject say what the tool can now **do**, rather than what was written (*code*, *source*, *files*, *content*)?
- [ ] Read each word of the subject aloud to someone who has not opened the diff: did you have to explain any of them?
- [ ] For each bullet: does it change what somebody **does**, or only what they read or how a thing is configured? If the latter, it belongs in the evidence record.
- [ ] Does any bullet only describe where a control moved, what a label says, or how a panel is arranged? The interface answers that; keep it only if it matters without seeing the app.
- [ ] Is there a bullet you cannot connect to the subject however you word it? That is evidence the commit holds two changes — split it.
- [ ] **Step 3.6:** Can I name the problem, the rejected alternative, the blast radius, the guardrail tests I ran, and the residual risk — from the diff, not from intention?
- [ ] Did every guardrail check actually **pass**, run from where it would really run? A run where everything failed is a wrong command until proven otherwise.
- [ ] **Step 3.7:** Did I run the reviewer pass before presenting, unprompted, and carry its objections into the draft?
- [ ] **Step 3.7:** Reading only the message, what would I wrongly believe is true? For each question I would ask, is the answer absent from both the change and the product interface?
- [ ] **Step 3.7:** Did the pass end in a verdict — merge or send back — rather than a note that it was reviewed?
- [ ] Were the changes **grouped by change** rather than staged as one blob or split by session? Would each proposed commit survive being read on its own?
- [ ] If a commit was kept whole rather than split, can one subject honestly summarize it?
- [ ] Delete each bullet in turn: would a reader notice its absence? If not, it goes.
- [ ] Does the subject alone state the whole outcome? If so, there should be no bullets.
- [ ] Am I describing a **problem solved**, not steps taken?
- [ ] Does each bullet describe **delivered impact**, not future work? Next steps belong in progress records, not history.
- [ ] Does each bullet add **new information** (no duplication)?
- [ ] Does any bullet belong in the project's evidence record rather than in history? Did I check that record for known limits the diff does not reveal?
- [ ] If the change is opt-in, adds a dependency, or gives something up, does the message say so?
- [ ] Are benefits **specific and measurable**, not vague?

### Red Flags (lint will catch these)

| Red Flag | Reason |
|---|---|
| Bullet starts with `-` | Use `*` for all bullets |
| Bullet contains `/` or `.md` / `.sh` / `.py` | Likely a file or directory reference — focus on outcomes |
| Bullet repeats the scope or title | Redundancy |
| Bullet contains jargon | Replace with natural language |
| WIP markers in body (`TODO`, `FIXME`, `WIP`) | Warning, not error |
| Forward-looking phrasing (`next step`, `follow-up`, `plan to`) | Warning, not error — describe delivered impact |
| `Closes:` / `Task:` / `Spec:` in the body | Use `--ref` instead |

---

## What This Skill Does NOT Do

- It does **not** install a pre-commit hook. Hooks are the user's choice.
- It does **not** read or write a `task.ctx` file.
- It does **not** check task phase or substance.
- It does **not** auto-commit. Human approval is required every time.
- It does **not** manage any state beyond `commit.diff` and `commit.draft`.

These are deliberate omissions — the skill is a single-concern tool, not an orchestrator.

---

## Installation

Drop `skills/draft-commit/` into your project:

```bash
# From the SWT project
cp -r skills/draft-commit/ <your-project>/.opencode/skills/draft-commit/

# Or any other agent discovery path your tool uses
```

Add to your `.gitignore`:

```gitignore
commit.diff
commit.draft
```

That's it. No config file, no environment variables, no setup wizard.

---

## Provenance

This skill is portable by design. It is **not** coupled to SWT (Simple Workflow Toolkit) or any other orchestrator. The original SWT-coupled version is preserved at `archive/skills/swt-commit/` for reference; that version includes task-context tracking and pre-commit hook integration, which this skill deliberately removes.
