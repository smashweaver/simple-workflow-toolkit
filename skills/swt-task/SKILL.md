---
name: "swt:task"
inherits: "swt:think"
description: >
  Owns the lifecycle of tasks in the `.tasks/` directory. Trigger when the user
  says "/swt:task", "list tasks", "create a new task", or "status of task X".
  Enforces naming conventions (no lifecycle verbs), provides standard templates
  for implementation and ideation, and handles the Phase 0 (Ideate) to Phase 1
  (Plan) graduation ritual.
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Write
  - Glob
  - Grep
---

# swt:task

Manages the lifecycle of tasks in the `.tasks/` directory.

## Behavioral Rules (MANDATORY)

- **Orientation Ritual**: Whenever a task is mounted (via `mount` or `focus`), the agent MUST run `xdg-open <task_file> &` (and its companion spec) to ensure a high-visibility orientation.
- **Manual Milestone Ritual**: The task manager handles task lifecycle but does NOT automatically trigger session digests. Digests are manual milestone rituals.

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

**Audience**: agent-driven, user-approved

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

**Audience**: user-invoked

Creates a Phase 0 brainstorm task for exploratory thinking before a plan exists.

**When to trigger:**
- User says "let's brainstorm", "I have an idea", "help me think through..."
- Exploratory conversation that doesn't yet have a defined plan
- `/swt:flow` Phase 0 entry signals (see `/swt:flow` skill)

**Context-Aware Behavior (DEFAULT):**
The agent **infers the topic from session context** — the user never needs to provide a topic argument explicitly. The topic argument to `task.sh brainstorm` is **optional**, not required. The agent:
1. Infers the topic from the current conversation context
2. Proposes the name via **Name Confirmation Gate** ("Proposed task name: `topic-name` — confirm or rename?")
3. Only then passes the topic to `scripts/task.sh brainstorm "<Topic>"`

**Steps:**
1. **Infer the topic** from session context (default) or accept explicit topic from user
2. Propose the slug name (name the **topic/thing**, not the activity) → wait for confirmation
3. Get timestamp
4. Write `.tasks/YYYYMMDDHHMMSS_slug.md` using the **Brainstorm Template** below
5. **Gate 1 (Alignment)**: Provide the link and ask: *"Brainstorm created: `[slug](path)`. Please review the Core Concept. Ready to begin?"*
6. **HARD STOP**: Do not begin the ideation conversation until the user explicitly confirms the task file.

> **Brainstorm Consistency Review (Ritual)**
> During Phase 0 iteration, the agent MUST periodically perform a self-review pass on the brainstorm document:
> - Check for stale unresolved questions (questions already answered but not updated)
> - Verify counts match (e.g., "10 targeted enhancements" vs actual list count)
> - Identify roadmap gaps (items in Impact Analysis not yet addressed)
> - Detect internal contradictions (conflicting statements within the document)
>
> This is a **formalized step in the brainstorm loop**, not something that only happens when the user asks "did you miss anything?"
> Trigger: After significant updates to the brainstorm document, or when the user signals readiness to graduate.

---

### Brainstorm Loop

The iteration cycle during Phase 0 where the agent refines the task file:

1. **Context pertains to current task**: If the user's prompt is related to the current brainstorm task, the agent MUST update the task file (add notes, refine objective, log jailbreak patterns, etc.).
2. **Unrelated issue worth investigating**: If the conversation reveals an unrelated problem that befits investigation, the agent MUST offer to create another brainstorm task (e.g., *"This seems like a separate issue worth brainstorming — want me to create a Phase 0 task for it?"*).
3. **Document Refresh Protocol**: When updating the task file (or any template-backed SWT document), use the Document Refresh Protocol below — not raw Edit tool operations.

---

### Document Refresh Protocol

Applies to **all template-backed SWT documents** (task files, SPEC.md, implementation_plan.md, task.md, commit.draft, etc.):

1. **Append** intended content to the document.
2. **Deduce** the backing template from document context:
   - Task files (`.tasks/<timestamp>_*.md`) → `skills/swt-task/templates/brainstorm.md` (Phase 0) or `task.md` template
   - `SPEC.md` → `skills/swt-task/templates/spec.md`
   - `implementation_plan.md` → `skills/swt-task/templates/implementation_plan.md`
   - `commit.draft` → standard draft format
3. **Reformat** the ENTIRE document using the backing template via `Write` tool.
4. **Why**: Eliminates Edit tool failures on special characters and structural divergence. Ensures Born Complete compliance.

---

### `/swt:task graduate` — Phase 0 → Phase 1 promotion

**Audience**: agent-driven, user-approved

Promotes a brainstorm task to an implementation task when the user is ready to build.

**When to trigger:**
- User says "ready to build", "let's plan this", "graduate this"
- End of a productive Phase 0 ideation session with clear direction

> 🛑 **Phase 0 Graduation Gate (MANDATORY)**
> Before invoking `swt.sh graduate`, the agent MUST:
> 1. Perform a **HARD STOP** and ask the user: *"Are we ready to graduate to Phase 1?"*
> 2. Wait for an explicit verbal **"Yes"** or **"Go"** from the user.
> 3. Only then invoke `swt.sh graduate <task_file>`.
> 4. After graduation, present the link and **HARD STOP** again (Gate 1: Alignment Loop).

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

**Audience**: agent-driven, user-approved

Updates the task checklist and phase field as phases complete.

**Steps:**
1. Read the active task file
2. Mark the completed phase: `- [ ]` → `- [x]`
3. Update `**Phase**` to the next active phase
4. If all phases are done, DO NOT close the task yet. Instruct the user to stage their files and invoke `/swt:commit`. The task will remain `pending` until the commit is applied.

> 🛑 **Phase 8 Iterative Gate (MANDATORY)**
> During Phase 8, the agent MUST NOT push the user toward `close`.
> - Phase 8 is an **iterative loop** — the user may append fine-tuning items via `swt.sh update <file> --append "item text"`.
> - The agent periodically asks *"Ready to close?"* but the **user always decides** when Phase 8 ends.
> - No auto-termination of Phase 8 — the loop continues as long as the user wants to refine.

---

### `/swt:task scaffold` — Generate root artifacts

**Audience**: agent-driven, automated

Generates `implementation_plan.md` from standard templates in `skills/swt-task/templates/`.

**When to trigger:**
- Automatically invoked by `graduate` (Phase 1) and `phase 8`.
- Manually invoked if an artifact needs to be recreated.

**Flags:**
- `--force`: Overwrite existing artifact.

---

### `/swt:task sync` — Synchronize root task.md

**Audience**: agent-driven, automated

Synchronizes the root `task.md` (Live Checklist) from the internal task file's `## Checklist` section.

**When to trigger:**
- Automatically invoked by `new`, `brainstorm`, `graduate`, and `phase`.
- Manually invoked if the root `task.md` gets out of sync or is accidentally deleted.

**Steps:**
1. Read the internal task file.
2. Extract the `## Checklist` section.
3. Overwrite the root `task.md` with the extracted checklist.
4. Confirm synchronization to the user.


---

### `/swt:task validate` — State verification

**Audience**: agent-driven

Validates the internal state of a task file against protocol rules.

**When to trigger:**
- Automatically invoked by `/swt:status`.
- Manually invoked if the agent suspects the task state is corrupted.

**Checks performed:**
- **Born Complete Rule**: Fails if `{{placeholder}}` text remains.
- **Exclusive Gateway**: Fails if the `**Phase**` header was manually edited without a matching `<!-- RITUAL -->` log.
- **Anti-Circling Gate**: Reads the entire breadcrumb history and checklist. Fails if previous phases were skipped or left incomplete, preventing agents from "circling" back or skipping mandatory planning phases.

---

### `/swt:task tidy` — Directory cleanup

**Audience**: user-invoked

Moves completed (`done`) or `abandoned` task files into the `.tasks/archive/` subfolder.

**When to trigger:**
- User explicitly says "/swt:task tidy"
- At the end of a session if there are several closed tasks in the root.

**Steps:**
1. Invoke `scripts/task.sh tidy`.
2. Confirm the result to the user (e.g., "Tidied 5 tasks into archive/").

---

### `/swt:task mount` — Mount active task context

**Audience**: user-invoked

Mounts the active task context so the agent knows what to work on. Resolves the task file, sets `task.ctx`, opens the task (and companion spec if available) in the system's default browser, reads the task state, and presents it to the user.

**When to trigger:**
- User says "mount X", "work on X", "switch to task X", "set mount to X"
- User invokes `/swt:task mount <name>` directly

**Steps:**
1. **Resolve the task file** by name/slug (check `.tasks/`, `.tasks/archive/`, accept bare slug, filename, or path):
   - Try `.tasks/*<name>*` (glob match on slug)
   - Try `.tasks/archive/*<name>*`
   - If multiple matches, present disambiguation list, **HARD STOP**
   - If no match, error and suggest `/swt:task list --open`
2. **Set context**: Run `RESOLVED=$(bash skills/swt-task/scripts/task.sh ctx set <resolved_file> | tail -1)` to capture the resolved path
3. **Read the task file** and extract key fields: Status, Phase, Objective/Core Concept, next unchecked item, and `**Spec**:` field
4. **Open in browser**:
   - `xdg-open "$RESOLVED" &` (falls back to `firefox` then `google-chrome` then `chromium` if `xdg-open` not found)
   - If the task has a `**Spec**: <spec_file>` field, also run `xdg-open <spec_file> &`
5. **Present to user**:
   > *"Mount set: `[slug](path)`*
   > *- Status: `<Status>` | Phase: `<Phase>`*
   > *- Next: `<next unchecked item or next step>`*
   > *Task and spec opened in default browser."*
   > *What would you like to do with this task?"*
6. **HARD STOP**: Wait for user direction before proceeding with any task work.

---

### `/swt:task list` — List tasks

**Audience**: user-invoked

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

### `/swt:task close` — Mark done

**Audience**: agent-driven, user-approved

Finalizes a task by updating metadata, checklists, and commit references. This command is the final act of a task ritual.

**Steps:**
1. Invoke `bash skills/swt-task/scripts/task.sh close <file> <commit_hash>`.
2. The script automatically:
   - Sets `**Status**` to `done`.
   - Sets `**Completed**` to current timestamp.
   - Marks ALL items in the `## Checklist` as `[x]`.
   - Appends the commit hash to the `## Commit Reference`.
3. Confirm the result to the user. *(Note: `task.ctx` is intentionally preserved after closure. It must only be cleared by the `/swt:commit` cleanup sequence.)*

---

### `/swt:task abandon` — Abandon a task

**Audience**: user-invoked

A dedicated operation to abandon a task. Semantically distinct from `close` — no commit hash required, status set to `abandoned`, checklist left as-is (not checked off). Also clears `task.ctx` if the abandoned task was mounted.

**When to trigger:**
- User says "abandon this task", "give up on X", "drop task X"
- User invokes `/swt:task abandon` directly

**Steps:**
1. **Resolve the task file** (same logic as `mount`): check `.tasks/`, `.tasks/archive/`, accept bare slug, filename, or path.
   - If no argument provided, default to the currently mounted task (read `task.ctx`).
   - If no task mounted and no argument, error and suggest `/swt:task list --open`.
2. **Update via script**: Run `bash skills/swt-task/scripts/task.sh abandon <resolved_file>`.
   - Script automatically sets `**Status**` to `abandoned`, sets `**Completed**` to timestamp.
   - Checklist is left AS-IS (not checked off).
   - `task.ctx` is preserved (not cleared) so the agent maintains context until explicitly directed otherwise.
3. **Confirm to user**: *"Task abandoned: `[slug](path)` (Status: abandoned, checklist unchanged)."*

**Semantic distinction from `close`:**
| Attribute | `abandon` | `close` |
|---|---|---|
| Status | `abandoned` | `done` |
| Commit hash | Not required | Required |
| Checklist | Left as-is | All items checked `[x]` |
| `task.ctx` | Preserved | Preserved |

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

### Ritual Templates

Templates for mandatory artifacts reside in `skills/swt-task/templates/`. These are the source of truth for all agents.

- **`implementation_plan.md`**: Phase 1 architectural and implementation roadmap.
- **`task.md`**: Phase 5 live checklist (synchronized from task file).
- **`spec.md`**: Phase 1 technical specification (generated during graduation).

## Brainstorm / Ideation Template

All brainstorming tasks created via `swt:task brainstorm` follow a high-fidelity structure designed to serve as a verification contract between agents:

```markdown
# Task: [Task Title]
**Created**: {{YYYY-MM-DD HH:MM:SS}}
**Updated**: —
**Completed**: —
**Status**: ideating
**Priority**: medium
**Type**: brainstorm
**Stack**: shared
**Phase**: 0
**Blocked By**: —

> **Covers**: [Summary line]

## What This Task Covers
1. [Area 1]
2. [Area 2]

## Guidance (Read Before Spec/Implementation/Walkthrough)
[Strategic intent and specific verification rituals.]

## Objective
[Problem statement and desired outcome.]

## Explored Alternatives
- Scenario A (Discipline)
- Scenario B (Automation)
- Scenario C (Enforcement)

## Artifact Phase Mapping
| Artifact | Generated | Phase | Gate |
|---|---|---|---|
| `implementation_plan.md` | Phase 1 | Plan | HARD STOP |
| `task.md` | Phase 5 | Implement | Checkpoint |
```

> **This task document structure is the template for future brainstorming tasks.** Use `## What This Task Covers` as the summary section.

## Unresolved Questions
{{What still needs to be answered before this graduates to a task?}}

## Impact Analysis (Roadmap)

#### Operations — What Changes:
| # | Operation | Status | Detail |
|---|---|---|---|
| 1 |  | **Modify** |  |
| 2 |  | **Modify** |  |
| 3 |  | No change |  |
| 4 |  | **Modify** |  |
| 5 |  | **Rename** |  |
| 6 |  | No change |  |
| 7 |  | **Modify** |  |
| 8 |  | **Rename** |  |
| 9 |  | **New** |  |

#### Audience Split:
| Audience | Operations |
|---|---|
| **User-invoked** |  |
| **Agent-driven, user-approved** |  |

#### Rules & Gates — What Changes:
| Rule | Status | Detail |
|---|---|---|
| Population Ritual (Born Complete) | No change | — |
| Naming Rules | No change | — |
| Name Confirmation Gate | No change | — |
| Uplink Protocol | No change | — |
| **Phase 0 Graduation Gate** | **New** | Agent MUST halt and ask for explicit verbal permission before running `swt.sh graduate` |
| **Phase 8 Iterative Gate** | **New** | Formally allows the user to keep a task open in Phase 8 for fine-tuning |
| **Brainstorm Consistency Review** | **New** | Formalizes agent's self-review pass during Phase 0 |

#### Touch Points (Files):
- `skills/swt-task/SKILL.md` —
- `skills/swt-task/scripts/task.sh` —
- `skills/swt-flow/SKILL.md` —
- `skills/swt-status/scripts/status.sh` —
- `AGENTS.md` —

## Notes

## Commit Reference
```

---

## Cross-References

- ⚠️ **The /swt:flow skill is the primary consumer of this skill.** All tasks created by `/swt:flow` must follow these rules.
- **`/swt:task mount`** — Mounts active task context. Integrates with:
  - `/swt:status`: Status shows mounted task; `mount` fulfills the "work on this one" signal after listing tasks.
  - `/swt:flow`: `mount` sets context before Phase1 planning; `/swt:flow` should suggest `mount` when no `task.ctx` is set.
  - `/swt:commit`: Commits must go through the skill (never direct `git commit`); staging via `git add .`; honor `commit.draft` refinement gate.
  - `/swt:init`: Newly bootstrapped workspaces discover `mount` in their AGENTS.md.
- **`/swt:spec`** — Calls `/swt:task new` after generating a `SPEC.md` to link an implementation task.
- **`/swt:init`** — Suggests `/swt:task new` after workspace bootstrap completes.

---

## Companion Skill

This skill **inherits from `swt:think`** (`skills/swt-think/SKILL.md`), which provides base behavioral principles for all AI agent reasoning. This skill adapts those principles specifically for task file lifecycle management.
