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

### 2. The Population Ritual (MANDATORY)

Immediately after creating a task file (and before presenting the link to the user), you MUST populate all placeholders:
- **Core Concept**: Replace with a detailed description.
- **Explored Alternatives**: Replace with actual Scenario-based trade-offs.
- **Notes**: Add any relevant context or evidence.

> 🛑 **The "Born Complete" Rule**: You are STRICTLY FORBIDDEN from presenting a "naked" template to the user. Every task must carry its full design rationale from birth. Failure to do so will cause `swt:task validate` to emit a protocol warning.


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

## Uplink Protocol (MANDATORY)

The "Uplink" is a mechanism to report SWT workflow friction from any project back to the core SWT backlog (`$SWT_HOME`). When a user hits a friction point with the toolkit itself — not their project — they can create a task in `$SWT_HOME/.tasks/` that includes session context about the issue.

**When to trigger:**
- User says "uplink this", "report this to swt", "swt needs a new skill", "this gate is annoying", etc.
- You identify a meta-issue with the toolkit itself while working on a project task.

**Steps:**
1. **Detect $SWT_HOME**: Ensure the environment variable is set.
2. **Determine the Topic**: Use the user's prompt or the identified friction point as the topic.
3. **Execute**: Run `bash skills/swt-task/scripts/task.sh brainstorm "Topic" --uplink`.
4. **Notify**: Confirm to the user: *"Insight uplinked to SWT core: `Topic`"*

> 💡 The script automatically captures the current project path, active task, and phase to provide context for the SWT maintainers.

### Developer Usage

The `--uplink` flag can also be invoked directly by developers from any workspace:

```bash
bash skills/swt-task/scripts/task.sh brainstorm "<SWT issue>" --uplink
```

**Requirements:**
- `$SWT_HOME` must point to the SWT toolkit project root
- `$SWT_HOME/.tasks/` must exist

**What gets captured** (written to the created task's `## Notes`):
| Context Field | Description |
|---|---|
| `**Source Project**` | Current working directory where the friction occurred |
| `**Source Task**` | Active task basename in the workspace being worked on |
| `**Source Phase**` | Current phase of that active task |

**Error behavior:**
- If `$SWT_HOME` is not set: prints error and exits
- If `$SWT_HOME/.tasks/` doesn't exist: prints error and exits
- No fallback to local `.tasks/` — the command only works when SWT_HOME is configured

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
1. Invoke `scripts/task.sh graduate <task_file>`.
2. This script handles:
   - Metadata update: `Phase: 0` → `1`, `Status: ideating` → `pending`.
   - **Type Check**: 
     - If `Type: feature`, it scaffolds a `SPEC.md` in `.specs/` and links it to the task.     - If `Type: refactor`, it appends a `## Verification Checklist` (Lite path).
   - Implementation checklist injection (Phases 1-8).
3. **Gate 1 (Alignment)**: Provide the link and ask: *"Task graduated: `[slug](path)`. Spec/Checklist generated. Please review. Ready to proceed to Phase 1: Plan?"*
4. **HARD STOP**: Do not proceed with technical planning until the user explicitly confirms the graduation.
5. Move into Phase 1 planning only after confirmation.

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

---

## Companion Skill

This skill **inherits from `swt:think`** (`skills/swt-think/SKILL.md`), which provides base behavioral principles for all AI agent reasoning. This skill adapts those principles specifically for task file lifecycle management.
