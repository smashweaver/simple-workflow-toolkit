---
name: "swt:task"
description: >
  Owns the lifecycle of tasks in the `.tasks/` directory. Trigger when the user
  says "/swt:task", "list tasks", "create a new task", or "status of task X".
  Enforces naming conventions (no lifecycle verbs), provides standard templates
  for implementation and ideation, and handles the Phase 0 (Ideate) to Phase 1
  (Plan) graduation ritual.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

You are the authoritative source for all task file operations in the Simple Workflow Toolkit. Every task file that gets created, graduated, updated, or closed goes through you. You enforce naming rules, select the right template, and always surface the proposed task name for user confirmation before writing anything to disk.

> 💡 **Smart Search**: When looking for a task file (e.g., to read its contents or resolve a `Blocked By` reference), if the file is not found in the root `.tasks/` directory, you **MUST** check the `.tasks/archive/` subfolder before reporting it as missing.

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

### `/swt:task new` — Standard task (Phase 1)

Creates a new implementation task ready for Phase 1 planning.

**When to trigger:**
- User explicitly requests a new task
- `/swt:flow` detects a non-trivial feature to implement
- `/swt:spec` generates a `SPEC.md` and offers to create a linked task

**Steps:**
1. Propose the slug name → wait for confirmation
2. Get timestamp: `date +%Y%m%d%H%M%S`
3. Write `.tasks/YYYYMMDDHHMMSS_slug.md` using the **Standard Task Template** below
4. **Gate 1 (Alignment)**: Provide the link and ask: *"Task created: `[slug](path)`. Please review the Objective and Checklist. Ready to proceed to Phase 1: Plan?"*
5. **HARD STOP**: Do not proceed with technical planning until the user explicitly confirms or fine-tunes the task file.
6. Use `scripts/task.sh` if available, otherwise write directly to the `.tasks/` directory.

---

### `/swt:task brainstorm` — Ideation task (Phase 0)

Creates a Phase 0 brainstorm task for exploratory thinking before a plan exists.

**When to trigger:**
- User says "let's brainstorm", "I have an idea", "help me think through..."
- Exploratory conversation that doesn't yet have a defined plan
- `/swt:flow` Phase 0 entry signals (see `/swt:flow` skill)

**Steps:**
1. Propose the slug name (name the **topic/thing**, not the activity) → wait for confirmation
2. Get timestamp
3. Write `.tasks/YYYYMMDDHHMMSS_slug.md` using the **Brainstorm Template** below
4. **Gate 1 (Alignment)**: Provide the link and ask: *"Brainstorm created: `[slug](path)`. Please review the Core Concept. Ready to begin?"*
5. **HARD STOP**: Do not begin the ideation conversation until the user explicitly confirms the task file.
6. Use `scripts/task.sh brainstorm "<Topic>"` if available.

---

### `/swt:task graduate` — Phase 0 → Phase 1 promotion

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
4. **Gate 1 (Alignment)**: Provide the link and ask: *"Task graduated: `[slug](path)`. Please review the updated Objective and Checklist. Ready to proceed to Phase 1: Plan?"*
5. **HARD STOP**: Do not proceed with technical planning until the user explicitly confirms the graduation.
6. Move into Phase 1 planning only after confirmation.

---

### `/swt:task update` — Mark progress

Updates the task checklist and phase field as phases complete.

**Steps:**
1. Read the active task file
2. Mark the completed phase: `- [ ]` → `- [x]`
3. Update `**Phase**` to the next active phase
4. If all phases are done, DO NOT close the task yet. Instruct the user to stage their files and invoke `/swt:commit`. The task will remain `pending` until the commit is applied.

---

### `/swt:task --tidy` — Directory cleanup

Moves completed (`done`) or `abandoned` task files into the `.tasks/archive/` subfolder.

**When to trigger:**
- User explicitly says "/swt:task --tidy"
- At the end of a session if there are several closed tasks in the root.

**Steps:**
1. Invoke `scripts/task.sh --tidy`.
2. Confirm the result to the user (e.g., "Tidied 5 tasks into archive/").

---

### `/swt:task list` — List tasks

Lists task files in the `.tasks/` directory, optionally filtered by status.

**Filter options:**
- `--open`: Tasks NOT in `done` or `abandoned` status. **MANDATORY**: Use this filter whenever the user asks "what's next?", "what should I do next?", "what are we working on?", "list open tasks", or "show task status".
- `--pending`: Standard implementation tasks.
- `--ideating`: Phase 0 brainstorm tasks.
- `--done`: Completed tasks in the root.
- `--all`: Every task file in the root (same as no filter).
- `--archived`: Only task files in the `archive/` subfolder.

**Steps:**
1. Determine the desired filter based on user request (e.g., "show open tasks").
2. Invoke `scripts/task.sh list [--filter]`.
3. Present the list to the user with their statuses.

---

### `/swt:task close` — Mark done or abandoned

**Steps:**
1. Set `**Status**` to `done` or `abandoned`
2. Set `**Completed**` to today's date
3. Add `**Commit Reference**` if applicable
4. Leave the file as an archived record — do not delete.

---

## Auto-Suggest Triggers

Other skills must proactively suggest `/swt:task` when these signals appear. Always use the **Name Confirmation Gate** when auto-suggesting.

| Signal | Triggered by | Prompt |
|---|---|---|
| User describes a non-trivial feature | `/swt:flow` | *"Shall I create a task file? Proposed name: `feature-name`"* |
| Phase 0 brainstorm has enough direction | `/swt:flow` | *"Ready to graduate? Proposed task: `feature-name`"* |
| `/swt:spec` generates a SPEC.md | `/swt:spec` | *"Spec created. Shall I link a task file? Proposed: `feature-name`"* |
| `/swt:init` completes bootstrap | `/swt:init` | *"Workspace ready. Create your first task? Proposed: `first-feature`"* |

---

## Execution Layer

**Preference order:**
1. `scripts/task.sh` — use when available (handles `.tasks/` init, `.gitignore` entries)
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
- **Scenario A (Discipline)**: {{Methodology/Rule change only}}
- **Scenario B (Automation)**: {{Helper scripts/Templates}}
- **Scenario C (Enforcement)**: {{Hard gates/Physical blocks}}

## Unresolved Questions
{{What still needs to be answered before this graduates to a task?}}

## Notes

## Commit Reference
```

---

## Cross-References

- ⚠️ **The /swt:flow skill is the primary consumer of this skill.** All tasks created by `/swt:flow` must follow these rules.
- **`/swt:spec`** — Calls `/swt:task new` after generating a `SPEC.md` to link an implementation task.
- **`/swt:init`** — Suggests `/swt:task new` after workspace bootstrap completes.
