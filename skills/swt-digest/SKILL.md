---
name: "swt:digest"
inherits: "swt:think"
description: >
  Automates the creation of structured session summaries for continuity.
  Trigger at the end of a session, after a major milestone, or when the user
  asks for a summary. Supports `--milestone` (or `-m`) for project roll-ups.
  Stores timestamped files in `.digests/`.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

# /swt:digest — Session Continuity Manager

You are responsible for capturing the "soul" of a coding session. Your goal is to synthesize complex conversations, technical decisions, and task states into a concise document that allows the *next* agent to hit the ground running.

---

## Storage & Naming

Summaries are stored in the `.digests/` directory at the project root.

- **Directory**: `.digests/` (ensure this is gitignored)
- **Filename (Session)**: `YYYYMMDDHHMMSS_digest.md`
- **Filename (Milestone)**: `YYYYMMDDHHMMSS_milestone.md`

---

## Protocol

When `/swt:digest` is invoked, follow these steps:

### 1. Gather Context
- **Mode Detection**: Check if the command was invoked with `--milestone` or `-m`.
- **Standard Mode (Session Summary)**:
    - **Previous Digests (Window of 5)**: List the last 5 files in `.digests/` (e.g., `ls -1 .digests/*_digest.md | tail -n 5`).
    - **Orphan Capture**: Read the content of any "orphaned" digests (not accounted for by successors) plus the latest digest to ensure 100% detail retention.
- **Milestone Mode (Project Roll-up)**:
    - **Find Boundary**: Locate the latest `*_milestone.md` file in `.digests/` or `.digests/archive/`.
    - **Filter Scope**: Consider `*_digest.md` files in **both** `.digests/` and `.digests/archive/` that have a timestamp **newer** than that milestone. These are your "unsynthesized" candidates.
    - **Deep Roll-up**: Synthesize all candidates into a single master document.
- **Deep History Retrieval**: If a current digest lists a parent in `.digests/archive/` that you need to examine for more detail, do not hesitate to read it. The archive is your "Long-Term Memory."
- **Tasks**: Scan the `.tasks/` directory for files that are NOT `done` or `abandoned`. **IMPORTANT**: Also scan `.tasks/archive/` for tasks that were closed or updated during the current session to ensure they are captured in the summary.
- **Changes**: Check `git status` or `git diff --cached` to see what was modified.
- **Conversation**: Review recent history and the identified previous digests to identify key outcomes, architectural decisions, and roadblocks.

### 2. Synthesize Outcomes
Identify the 3–5 most important achievements or decisions from the session. Focus on the *why* and the *impact*. **Recursive Awareness**: Carry forward any critical architectural decisions from the previous digest that remain relevant.

### 3. Identify Next Steps
Look at the active tasks, current conversation, and the "Next Steps" from the previous digest. If previous steps are still unresolved, carry them forward or update them to reflect new priorities.

### 4. Write the Digest
- Use the **Session Summary Template** for standard sessions.
- Use the **Project Milestone Template** if `--milestone` was specified.

---

## Session Summary Template

```markdown
# SWT Session Summary — {{YYYY-MM-DD}}

{{A 1-2 sentence summary of the session's primary focus.}}

## Key Outcomes & Architecture

- **{{Outcome Title}}**: {{Brief explanation of what was decided/built and its impact.}}
- ...

## Active Tasks in `.tasks/`

- **[{{task-slug}}]({{file-path}})**: ({{Priority}}) {{Status summary}}
- ...

## Changes & Cleanup

- {{List of files created, modified, or deleted with brief rationale.}}
- ...

## Immediate Next Steps

1. **{{Step 1}}**: {{Actionable item}}
2. ...

## Synthesized Parent Digests

- .digests/archive/{{Filename of synthesized digest 1}}
- .digests/archive/{{Filename of synthesized digest 2}}
```

### Project Milestone Template

```markdown
# SWT Project Milestone Digest — {{YYYY-MM-DD}}

This comprehensive synthesis rolls up the recent evolution of the {{Project Name}} into a single "Source of Truth," capturing the major architectural pillars and current project state. This digest serves as a master roll-up of all previous unsynthesized session summaries.

## Key Outcomes & Architecture Pillars

- **{{Pillar Title}}**: {{Brief explanation of the pillar, its implementation, and its impact on the project's foundation.}}
- ...

## Project History & Evolution

- **{{Milestone Title}}**: {{A high-level summary of a major project phase or breakthrough captured in this roll-up.}}
- ...

## Active Tasks in `.tasks/`

- **[{{task-slug}}]({{file-path}})**: ({{Priority}}) {{Status summary}}
- ...

## Immediate Next Steps

1. **{{Step 1}}**: {{Actionable item}}
2. ...

## Synthesized Parent Digests

- This digest synthesizes the following unsynthesized history:
- .digests/archive/{{Filename 1}}
- .digests/archive/{{Filename 2}}
```

---

## Protocol Guardrails

- **No Autonomous Generation**: Agents are STRICTLY FORBIDDEN from generating digests unless explicitly requested by the user or triggered by a documented ritual (e.g., end-of-session goodbye).
- **Source of Truth Verification**: Never invent progress. If a task status is unclear, ask the user before writing it into the digest.

---

## Auto-Suggest Triggers

Proactively suggest `/swt:digest` when:
- The user says "goodbye", "talk to you later", or "done for now".
- After a successful `/swt:commit` that closes a major task.
- When shifting between significant context areas (e.g., from Frontend to Backend).

---

## Execution Layer (MANDATORY)

You MUST use the automated script to generate digests. Never attempt to manually construct the timestamp or file structure.

1. **Run the script**: `bash skills/swt-digest/scripts/digest.sh --summary "<Key Outcomes>"`
2. **Optional Flags**:
    - `--milestone`: Generate a project roll-up.
    - `--content <file>`: Use a scratch file for complex, multi-line summaries.
3. **Post-Creation**: The script automatically handles parent archival.
4. **Confirm to user**: *"Digest created: `.digests/YYYYMMDDHHMMSS_{digest|milestone}.md`. (Archived parents). See you next time!"*

---

## Companion Skill

This skill **inherits from `swt:think`** (`skills/swt-think/SKILL.md`), which provides base behavioral principles for all AI agent reasoning. This skill adapts those principles specifically for session digest generation.
