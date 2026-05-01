---
name: "swt:status"
description: >
  Aggregates project state (latest digest, active tasks, recent specs, and
  optional git history) to restore session context or provide a quick progress
  update.
user-invocable: true
allowed-tools:
  - Read
  - Bash
---

# swt:status

Aggregates project state (latest digest, active tasks, recent specs, and optional git history) to restore session context or provide a quick progress update.

## Triggers
- "whats up"
- "where am I?"
- "resume session"
- "status"

## Operations

### `/swt:status` — Standard status report
**Audience**: user-invoked, agent-driven
Aggregates project state (latest digest, active tasks, recent specs) to restore session context or provide a quick progress update.

### `/swt:status --git` — Status report with git history
**Audience**: user-invoked
Aggregates project state and includes the last 5 git commits for additional context.

## Behavior
1. **Workspace Discovery**: Walks up the tree to find the root `AGENTS.md` or `.git`.
2. **Digest Retrieval**: Locates the newest `.md` in `.digests/` (or `.digests/archive/`).
3. **Task Scanning**: Lists all files in `.tasks/` that are not `done` or `abandoned`.
4. **Validation**: Executes `task.sh validate` for each active task.
5. **Spec Discovery**: Lists the 3 most recently updated files in `.specs/`.
6. **Git History (Optional)**: If `--git` is provided, displays the last 5 commits (`oneline`).

## Senior Advisor Guidance
- **Orientation Ritual (MANDATORY)**: Upon presenting the status, the agent MUST run `xdg-open <task_file> &` (and its companion spec) for the currently mounted task (from `task.ctx`) to ensure a high-visibility orientation.
- **Manual Milestone Ritual**: The `swt:status` skill provides a state summary but does NOT automatically trigger a new digest. Digests are manual rituals reserved for logical session ends or major milestones.
- Use this skill at the beginning of every session to ensure alignment with the documented state.
- If the "Latest Digest" contradicts your current understanding, prioritize the digest and ask for clarification.
- Always perform a **HARD STOP** after presenting the status to allow the user to course-correct.
