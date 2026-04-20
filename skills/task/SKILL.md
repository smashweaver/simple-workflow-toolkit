---
name: task
description: >
  Use when creating, updating, graduating, or closing a task file. Trigger when
  the user says things like "create a task for this", "make a task file", "let's
  track this", "/task new", "/task brainstorm", or when a non-trivial feature or
  idea surfaces in conversation that deserves tracking. Also trigger during
  /workflow Phase 0 graduation ("ready to build"), post-/spec generation, and
  post-/init bootstrap. This skill is the single authoritative source for all
  task lifecycle rules: naming, templates, graduation rituals, and status
  updates. All other skills that create or modify tasks MUST follow this skill's
  naming rules and use the Name Confirmation Gate.
user-invokable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /task — Task Lifecycle Management

You are the authoritative source for all task file operations in the Diskarte toolkit. Every task file that gets created, graduated, updated, or closed goes through you. You enforce naming rules, select the right template, and always surface the proposed task name for user confirmation before writing anything to disk.

---

## Naming Rules (MANDATORY — read first)

Task filenames are **permanent identifiers** that must stay accurate throughout the entire lifecycle — from ideation through to the final commit. Apply these rules without exception.

### The Core Rule

> **Name the thing being built, not what you are doing to it.**

The name should answer: *"What feature, fix, or outcome does this task produce?"*

### Forbidden patterns

Never use lifecycle verbs as prefixes or suffixes:

| ❌ Forbidden | ✅ Correct |
|---|---|
| `ideate-init-skill` | `init-skill` |
| `brainstorm-user-auth` | `user-auth` |
| `fix-login-bug` | `login-bug` or `session-token-validation` |
| `update-readme` | `readme-skills-table` |
| `implement-payments` | `payment-integration` |

### Format

```
YYYYMMDDHHMMSS_slug.md
```

- Timestamp = current local time at moment of file creation
- Slug = lowercase, hyphens only, no special characters, no lifecycle verbs
- Max 4–5 words: describe the feature or outcome concisely

---

## Name Confirmation Gate (MANDATORY)

Before writing **any** task file to disk, the agent MUST:

1. **Propose the name** in chat:
   > *"Proposed task name: `init-skill` — confirm or rename?"*
2. **Wait for explicit user response** before proceeding.
3. **Apply any correction** the user requests, then write the file.

> 🚫 No silent file creation. Ever. This gate is the primary naming enforcement mechanism.

---

## Operations

### `/task new` — Standard task (Phase 1)

Creates a new implementation task ready for Phase 1 planning.

**When to trigger:**
- User explicitly requests a new task
- `/workflow` detects a non-trivial feature to implement
- `/spec` generates a `SPEC.md` and offers to create a linked task

**Steps:**
1. Propose the slug name → wait for confirmation
2. Get timestamp: `date +%Y%m%d%H%M%S`
3. Write `.tasks/YYYYMMDDHHMMSS_slug.md` using the **Standard Task Template** below
4. Confirm to user: *"Task created: `.tasks/YYYYMMDDHHMMSS_slug.md`. Ready for Phase 1: Plan."*
5. Use `scripts/taskmgr.sh new "<Name>"` if the script is available; otherwise create the file directly.

---

### `/task brainstorm` — Ideation task (Phase 0)

Creates a Phase 0 brainstorm task for exploratory thinking before a plan exists.

**When to trigger:**
- User says "let's brainstorm", "I have an idea", "help me think through..."
- Exploratory conversation that doesn't yet have a defined plan
- `/workflow` Phase 0 entry signals (see `/workflow` skill)

**Steps:**
1. Propose the slug name (name the **topic/thing**, not the activity) → wait for confirmation
2. Get timestamp
3. Write `.tasks/YYYYMMDDHHMMSS_slug.md` using the **Brainstorm Template** below
4. Begin ideation conversation — do not rush into planning
5. Use `scripts/taskmgr.sh brainstorm "<Topic>"` if available.

---

### `/task graduate` — Phase 0 → Phase 1 promotion

Promotes a brainstorm task to an implementation task when the user is ready to build.

**When to trigger:**
- User says "ready to build", "let's plan this", "graduate this"
- End of a productive Phase 0 ideation session with clear direction

**Steps:**
1. Read the active brainstorm task file
2. Update the following fields:
   - `**Status**`: `ideating` → `pending`
   - `**Type**`: `brainstorm` → appropriate type (`feature`, `bugfix`, `chore`, `docs`, `refactor`)
   - `**Phase**`: `0` → `1`
3. Append the standard 8-phase `## Checklist` if not already present
4. Confirm: *"Task graduated. Proceeding to Phase 1: Plan."*
5. Move immediately into Phase 1 planning — no new file needed.

---

### `/task update` — Mark progress

Updates the task checklist and phase field as phases complete.

**Steps:**
1. Read the active task file
2. Mark the completed phase: `- [ ]` → `- [x]`
3. Update `**Phase**` to the next active phase
4. If all phases are done, DO NOT close the task yet. Instruct the user to stage their files and invoke `/commit`. The task will remain `pending` until the commit is applied.

---

### `/task list` — List tasks

Lists task files in the `.tasks/` directory, optionally filtered by status.

**Filter options:**
- `open`: Tasks NOT in `done` or `abandoned` status (default recommendation for "what's next").
- `pending`: Standard implementation tasks.
- `ideating`: Phase 0 brainstorm tasks.
- `done`: Completed tasks.
- `all`: Every task file (same as no filter).

**Steps:**
1. Determine the desired filter based on user request (e.g., "show open tasks").
2. Invoke `scripts/taskmgr.sh list [filter]`.
3. Present the list to the user with their statuses.

---

### `/task close` — Mark done or abandoned

**Steps:**
1. Set `**Status**` to `done` or `abandoned`
2. Set `**Completed**` to today's date
3. Add `**Commit Reference**` if applicable
4. Leave the file as an archived record — do not delete.

---

## Auto-Suggest Triggers

Other skills must proactively suggest `/task` when these signals appear. Always use the **Name Confirmation Gate** when auto-suggesting.

| Signal | Triggered by | Prompt |
|---|---|---|
| User describes a non-trivial feature | `/workflow` | *"Shall I create a task file? Proposed name: `feature-name`"* |
| Phase 0 brainstorm has enough direction | `/workflow` | *"Ready to graduate? Proposed task: `feature-name`"* |
| `/spec` generates a SPEC.md | `/spec` | *"Spec created. Shall I link a task file? Proposed: `feature-name`"* |
| `/init` completes bootstrap | `/init` | *"Workspace ready. Create your first task? Proposed: `first-feature`"* |

---

## Execution Layer

**Preference order:**
1. `scripts/taskmgr.sh` — use when available (handles `.tasks/` init, `.gitignore` entries)
2. Direct file creation — fallback if script is not present

Both paths go through the **Name Confirmation Gate** before any file is written.

---

## Templates

### Standard Task Template

```markdown
# Task: {{Task Name}}
**Created**: {{YYYY-MM-DD HH:MM:SS}}
**Updated**: —
**Completed**: —
**Status**: pending
**Priority**: medium          <!-- low | medium | high | critical -->
**Type**: feature             <!-- feature | bugfix | refactor | chore | docs -->
**Stack**: shared             <!-- frontend | backend | shared -->
**Phase**: 1                  <!-- current active phase (1–8) -->
**Blocked By**: —

## Objective
{{What this task achieves when complete.}}

## Checklist
- [ ] Phase 1: Plan
- [ ] Phase 2: Analyze
- [ ] Phase 3: Risk Assessment
- [ ] Phase 4: Approval
- [ ] Phase 5: Implement
- [ ] Phase 6: Document
- [ ] Phase 7: Test
- [ ] Phase 8: Iterative Development

## Notes

## Risks

## Commit Reference
```

### Brainstorm / Ideation Template

```markdown
# Task: {{Topic or Idea Name}}
**Created**: {{YYYY-MM-DD HH:MM:SS}}
**Updated**: —
**Completed**: —
**Status**: ideating          <!-- ideating | pending | in-progress | done | abandoned -->
**Priority**: medium          <!-- low | medium | high | critical -->
**Type**: brainstorm          <!-- brainstorm | feature | bugfix | refactor | chore | docs -->
**Stack**: shared             <!-- frontend | backend | shared -->
**Phase**: 0                  <!-- 0 = ideating, 1–8 = implementation phases -->
**Blocked By**: —

## Core Concept
{{What is the core problem or idea being explored?}}

## Explored Alternatives
{{What other approaches were considered and why set aside?}}

## Unresolved Questions
{{What still needs to be answered before this graduates to a task?}}

## Notes

## Commit Reference
```

---

## Cross-References

- **`/workflow`** — References this skill for all task creation and lifecycle rules. The Task Manager Protocol in `/workflow` is replaced by a pointer here.
- **`/spec`** — Calls `/task new` after generating a `SPEC.md` to link an implementation task.
- **`/init`** — Suggests `/task new` after workspace bootstrap completes.
