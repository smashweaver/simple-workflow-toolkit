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

## Protocol Validation (run before drafting)

- [x] Re-read this SKILL.md
- [x] Verified the lint script (`scripts/lint.sh`) is present and executable
- [x] Checked for red flags in the staged diff (no WIP markers, no debug statements)
- [x] Verified Repo Hygiene (no leftover `commit.diff` / `commit.draft` in the working tree)

> [!CAUTION]
> **Zero Tolerance for Structural Noise**: Bullets MUST focus on outcomes. File paths, extensions, and internal refactoring details are forbidden in commit messages. Lint will fail them.

---

## Diff-First Workflow

**Draft-and-Approve**: All commits go through a formal draft phase for human review. The skill never auto-commits — the human always says "apply."

Two temporary files are used (both should be in your `.gitignore`):
- **`commit.diff`** — the staged diff exported from git
- **`commit.draft`** — the agent-drafted commit message, ready for review

### Step 0 — Preview on unstaged files (optional)

```bash
bash skills/draft-commit/scripts/draft-commit.sh --preview
bash skills/draft-commit/scripts/draft-commit.sh --preview --draft "type(scope): summary

* bullet: user benefit or impact"
```

Preview gets the diff on unstaged files and applies the draft-commit logic to it: status plus unstaged diff stats, protocol validation on the unstaged diff (WIP markers, debug statements, repo hygiene), then the full unstaged diff itself for drafting, and, with `--draft`, an in-memory lint of the message. It never stages anything and never writes `commit.diff` or `commit.draft`.

### Step 1 — Stage your changes

```bash
git add .               # stage all changes respecting .gitignore
git status              # verify what is staged
```

To unstage a specific file:
```bash
git reset HEAD <file>
```

### Step 2 — Capture the staged diff

```bash
git diff --cached > commit.diff
```

### Step 3 — Generate a validated commit draft

**Establish purpose first.** Read the repository's own statement of purpose (README, PRD, brief,
issue) and write one sentence naming what this change is evidence of, enables, or settles. Every
bullet and the subject are measured against that sentence, not against the diff. A person reading
`git log` should not have to open the README to learn why the code matters.

Write the outcome bullets first, then derive the subject from their main outcome.
The subject must make sense on its own and summarize what changed concretely;
minor supporting details can remain in the bullets. For a single-line change,
write that outcome directly as the subject.

Avoid vague subjects such as `clarify requirements`. Verbs like "update,"
"improve," or "clarify" are useful only when the subject states the concrete
change. For example, bullets establishing a required CLI and proposal conventions
support `chore(workflow): define CLI requirements and proposal conventions`.

Run the skill with your draft message. The skill runs it through the lint gate and saves the validated version to `commit.draft`. The lint checks syntax; the agent must also check that the subject accurately summarizes the bullets.

```bash
# Standard usage: skill generates the draft from your message
bash skills/draft-commit/scripts/draft-commit.sh --draft "type(scope): summary

* bullet: user benefit or impact
* bullet: additional distinct information"

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
- **Am I holding back something only I can notice?** If the diff contains something the message will
  not say, or a limit you are hoping nobody asks about, that belongs in the draft. Raising it costs
  one sentence; being caught omitting it costs the whole message.

**Surface the revision, do not just perform it.** When you revise, show what changed and why. A
draft that appears already-perfect after three silent passes teaches the human nothing about where
the traps are, and the next one gets the same treatment. If the human asked for a critique and you
found nothing, say so briefly — do not manufacture objections to look thorough.

Critique against the purpose sentence from Step 3. Work in order — the first check decides whether
the others can land.

1. **Can you follow the main line?** State the change back as plain behavior in one sentence, the
   way you would to a colleague who has not opened the diff. If you cannot do that with ordinary
   words, the subject is aimed at the repository rather than at a reader, and that is the defect. A
   reader who understands every word and still has to work out what happened has not been told the
   main line.

   **No coined terms in a subject.** Flag every word that this project invented, defined in its own
   record, or uses to mean something other than its ordinary meaning — *scripted*, *island*,
   *enhanced*, *native*, *shape*, *replay*, *admission* are all common coinages in software. Each is
   legible to the team and opaque outside it, and the reader pays for it.

   The plain word is nearly always available: **a request made by JavaScript** for "scripted", **part
   of a page** for "island", **a size limit** for "bound". When the plain word feels less precise, the
   precision belongs in a bullet — the headline's job is to be understood, not to be exact.

   A coined term earns a place in a subject only when it names a genuine load-bearing concept with no
   plainer synonym. Even then, spell it out in the first bullet.
2. **Contribution, not contents.** Would someone reading only this message learn what the change
   makes possible, or merely what it contains? A message a reader could use to reconstruct the
   implementation is describing contents.
3. **Duplication.** Does any bullet restate the subject, or two bullets argue the same point?
   Merge them and spend the freed slot on something the reader does not yet know.
4. **Evidence in the wrong place.** A bullet reciting test results belongs in the project's
   evidence record, not in history. History says what was settled.
5. **Missing reassurance.** What would the reader's first question be — "does this change what I
   have?", "what does it cost?", "is it on by default?" — and does the message answer it? If the
   change is opt-in, say so. If it gives something up, say what.
6. **Bullet legibility.** Read each bullet on its own and check four things:
   - **One clause before the verb.** If three modifiers stack up before the main verb, the point is
     at the end of the sentence where nobody reads. Put the verb first.
   - **The term rule applies to bullets too.** A subject cleaned of coined terms while its bullets
     keep "shape", "fragment", and "replay" has only half been fixed — the reader still pays, and
     now pays again after reading on. Same substitution: a term a reader must look up belongs in the
     diff, not the history.
   - **No invented plain-sounding name for a missing thing.** Do not coin a friendly phrase like
     "page-part lookup" for an absent mechanism. That sends a reader looking for something that was
     never built. Name the real mechanism, or describe the absence in ordinary words ("nothing looks
     up which part of a page was asked for").
   - **Under 30 words.** Longer than that and it is a paragraph that should be split or cut. A bullet
     carrying an argument about *why* usually wants the argument kept and the explanation dropped.
7. **Subject accuracy.** Does the subject still summarize the revised bullets, and does it stand
   alone?

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

### Step 4 — Fine-tune

The user may edit `commit.draft` directly in their editor, or ask the agent to make specific changes. The skill itself does not run iteration; the agent does, in conversation with the user.

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

```
<type>(<scope>): <short, descriptive summary>

* What users gain from the change
* How the change improves user experience
* What problems it solves or prevents
* Performance or architectural improvements
```

Skip the bullet block if the commit is a single-line change (e.g. typo fix, version bump).

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

Run this in Step 3.5, before presenting a draft to the human. It is the agent's own check, not a
formality — the human should not be the one finding these.

- [ ] Does the subject summarize the bullets' main outcome and stand on its own, without listing every minor detail?
- [ ] Can a reader state what changed, in plain behavior, without an internal term or a chapter name?
- [ ] Is every word in the subject ordinary English that a reader outside this project would use?
- [ ] Does each bullet reach its verb within one clause, and stay under 30 words?
- [ ] Do the bullets avoid coined terms too, and name absent mechanisms by their real name or in plain words?
- [ ] Does the subject say what the change **contributes** to this repository, not only what it contains?
- [ ] Could a reader use these bullets to reconstruct the implementation? If so, they describe contents rather than contribution.
- [ ] Would someone understand the **impact** without knowing implementation?
- [ ] Can I remove any bullet that just restates the title?
- [ ] Am I describing a **problem solved**, not steps taken?
- [ ] Does each bullet describe **delivered impact**, not future work? Next steps belong in progress records, not history.
- [ ] Does each bullet add **new information** (no duplication)?
- [ ] Does any bullet belong in the project's evidence record rather than in history?
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