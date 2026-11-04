---
name: "handover"
description: Draft-and-Approve handover doc ritual. Verify HANDOVER.md against git status and fixtures, draft changes in chat, and apply only after human approval. Drop into any repo.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# handover — Portable Handover Ritual

Handover documents ensure that an agent or developer resuming in a new session has an exact, truthful snapshot of the project's state. When handover docs drift from git commits, working tree status, or referenced fixtures, they mislead subsequent sessions.

This skill enforces a **Display-then-Apply** workflow: the agent verifies the existing state, drafts updates in chat first, and updates `HANDOVER.md` only upon explicit approval.

---

## Protocol Validation (run before drafting)

- [ ] Ensure `HANDOVER.md` is gitignored (`.gitignore` or `.git/info/exclude`) — handover files must remain local-only.
- [ ] Run `scripts/verify-handover.sh [path/to/HANDOVER.md]` to inspect current discrepancies.
- [ ] Check `git rev-parse --short HEAD` and `git log -1 --oneline`.
- [ ] Check `git status --short` for uncommitted work.
- [ ] Check existence of any referenced temporary files/fixtures in `/tmp`.

---

## Workflow

### Step 1 — Verify existing handover state

Run the validator script:

```bash
skills/handover/scripts/verify-handover.sh HANDOVER.md
```

Identify any discrepancies:
- Commit SHA mismatch with HEAD.
- Mismatched uncommitted work vs `git status`.
- Missing temporary fixtures or test prerequisites.
- Stale dates.

### Step 2 — Draft the updated handover in chat

Draft the updated document or diff directly in chat. Follow `templates/handover.md` structure:
- **Checkpoint & Scope**: Accurate HEAD sha, date, current branch, boundaries of scope.
- **Working tree status**: Accurate list of modified/untracked files or clean status.
- **Focus for next session**: Current unresolved questions, next prioritized tasks.
- **Other open work**: Non-blocking items, deferred spikes.
- **Implementation rules to preserve**: Project invariants and architecture rules.
- **Verification & resuming**: Validated commands, fixture paths, notes on temporary files.
- **Working preferences**: Rituals and conventions.

Never write directly to `HANDOVER.md` during drafting.

### Step 3 — Approval Gate (HARD STOP)

> 🚫 **Do not write to `HANDOVER.md` unless the user gives explicit verbal approval (e.g., "apply").**

Display the draft and present:

---
**Apply this handover update to HANDOVER.md?**
- **Apply** — write update to `HANDOVER.md`
- **Fine-tune** — tell me what to adjust
---

### Step 4 — Write and verify

On explicit "apply":
1. Update `HANDOVER.md`.
2. Run `skills/handover/scripts/verify-handover.sh HANDOVER.md` to verify clean pass.

