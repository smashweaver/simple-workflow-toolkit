---
name: "draft-digest"
description: Draft-and-Approve session digest ritual. Display a session summary in chat first, then save to .digests/ on human approval. Context is thread, git diffs, or a commit ref. No dependencies, no merge engine, no auto-write.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# draft-digest — Portable Digest Ritual

Session digests make past work recoverable. This skill enforces a Display-then-Apply workflow: the agent always shows the digest in chat first, and only writes to `.digests/` after explicit human approval. It is self-contained: no Python merge engine, no parent archival, no task manager. Drop the `skills/draft-digest/` directory into any git repo and it works.

---

## Protocol Validation (run before drafting)

- [x] Re-read this SKILL.md
- [x] Determined context source (thread, diffs, or commit — ask the human if unclear)
- [x] Checked `.digests/` exists (create it on apply if missing)
- [x] No placeholders will appear in the digest (see lint)

---

## Workflow

### Step 1 — Ask for context

Ask one question before drafting:

> **Context for this digest: thread, diffs, or commit?**
> - **Thread** — summarize the conversation / session from chat history
> - **Diffs** — summarize from `git status`, `git diff --stat`, `git diff`
> - **Commit** — summarize from a given ref or latest commit (`<ref>` defaults to `HEAD`)

If the human already specified, skip the question.

For **diffs**, run:

```bash
git status --short
git diff --stat
git diff
git diff --cached --stat
git diff --cached
```

For **thread**, use the conversation history. No git reads required.

For **commit**, run (`<ref>` defaults to `HEAD`):

```bash
git log --oneline -5
git show --stat <ref>
git show <ref>
```

### Step 2 — Display the digest

Render the digest **in chat** using `templates/session.md`. Follow the Quality Checklist. Never write a file at this stage.

### Step 3 — Approval Gate (HARD STOP)

> 🚫 **The skill is STRICTLY FORBIDDEN from writing to `.digests/` unless the user gives explicit approval.**

After displaying the digest, present this binary choice:

---
**Save this digest?**
- **Apply** — write to `.digests/YYYYMMDDHHMMSS_digest.md`
- **Fine-tune** — tell me what to change
---

The user must say "apply" (or equivalent) before anything is written.

### Step 4 — Save (human-executed approval only)

On explicit "apply" confirmation:

```bash
mkdir -p .digests
DIGEST=".digests/$(date -u +%Y%m%d%H%M%S)_digest.md"
```

Write the approved digest text to `$DIGEST` verbatim. Report the path back.

---

## Format

See `templates/session.md` for the canonical structure:

```
# <Title> — YYYY-MM-DD

<1-2 sentence lede>

## Key Outcomes & Architecture
## Technical Retrospective (Hurdles & Friction)
## Changes & Cleanup
## Immediate Next Steps
## Synthesized Parent Digests
```

---

## Quality Checklist

Before displaying, verify:

- [ ] Lede states **what happened**, not steps taken?
- [ ] Outcomes describe **delivered impact**, not future work? (Plans belong in Next Steps.)
- [ ] Each bullet adds **new information** (no duplication)?
- [ ] No placeholders: `TODO`, `TBD`, `{{...}}`, `[...]`, empty sections?
- [ ] Parent digest referenced (latest file in `.digests/`), or "None — first digest"?

### Red Flags

| Red Flag | Reason |
|---|---|
| Placeholder or empty section | Fail — fill it or drop the section |
| Future work in Outcomes | Move to Next Steps |
| Vague bullet ("various fixes") | Make specific, or drop |

---

## What This Skill Does NOT Do

- It does **not** auto-write to `.digests/`. Human approval is required every time.
- It does **not** merge or archive parent digests. Linear chain only.
- It does **not** read or write a `task.ctx` file.
- It does **not** manage any state beyond the single digest file.

---

## Installation

Drop `skills/draft-digest/` into your project:

```bash
cp -r skills/draft-digest/ <your-project>/.opencode/skills/draft-digest/
```

That's it. No config file, no environment variables, no setup wizard.
