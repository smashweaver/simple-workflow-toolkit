---
name: "commit"
description: Draft-and-Approve commit ritual with a lint gate. Drop into any git repo. Use when writing commit messages or creating commits. Produces impact-focused, no-structural-noise commit messages via a human-in-the-loop approval step. No dependencies on task managers, state machines, or workflow orchestrators.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# commit — Portable Commit Ritual

Impact-focused commit messages make code history readable and maintainable. This skill enforces a Draft-and-Approve workflow with a lint gate. It is self-contained: no task manager, no state machine, no pre-commit hook installed by the skill. Drop the `skills/commit/` directory into any git repo and it works.

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

Run the skill with your draft message. The skill runs it through the lint gate and saves the validated version to `commit.draft`.

```bash
# Standard usage: skill generates the draft from your message
bash skills/commit/scripts/commit.sh --draft "type(scope): summary

* bullet: user benefit or impact
* bullet: additional distinct information"

# With an optional reference (e.g. for issue trackers)
bash skills/commit/scripts/commit.sh --draft "type(scope): summary

* bullet" --ref "Fixes #42"

# With a pre-written message file
bash skills/commit/scripts/commit.sh --draft "$(cat /tmp/msg.txt)"
```

The skill will:
1. Run the lint gate against your draft.
2. If lint passes, save the draft to `commit.draft` and print it for review.
3. If lint fails, print the errors and exit non-zero. Self-correct and retry (max 3 attempts).

> ⚠️ **The skill MUST NOT execute any `git commit` command at this stage.** Approval is the human's call.

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

Before committing, verify:

- [ ] Would someone understand the **impact** without knowing implementation?
- [ ] Can I remove any bullet that just restates the title?
- [ ] Am I describing a **problem solved**, not steps taken?
- [ ] Does each bullet add **new information** (no duplication)?
- [ ] Are benefits **specific and measurable**, not vague?

### Red Flags (lint will catch these)

| Red Flag | Reason |
|---|---|
| Bullet starts with `-` | Use `*` for all bullets |
| Bullet contains `/` or `.md` / `.sh` / `.py` | Likely a file or directory reference — focus on outcomes |
| Bullet repeats the scope or title | Redundancy |
| Bullet contains jargon | Replace with natural language |
| WIP markers in body (`TODO`, `FIXME`, `WIP`) | Warning, not error |
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

Drop `skills/commit/` into your project:

```bash
# From the SWT project
cp -r skills/commit/ <your-project>/.opencode/skills/commit/

# Or any other agent discovery path your tool uses
```

Add to your `.gitignore`:

```gitignore
commit.diff
commit.draft
```

That's it. No config file, no environment variables, no setup wizard.

---

## Companion Documentation

This skill is portable by design. It is **not** coupled to SWT (Simple Workflow Toolkit) or any other orchestrator. The original SWT-coupled version is preserved at `archive/skills/swt-commit/` for reference; that version includes task-context tracking and pre-commit hook integration, which this skill deliberately removes.
