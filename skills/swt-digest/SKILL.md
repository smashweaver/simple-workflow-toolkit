---
name: "swt:digest"
description: >
  Automates the creation of structured session summaries for continuity.
  Trigger at the end of a session, after a major milestone, or when the user
  asks for a summary. Stores timestamped files in `.digest/`.
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

Summaries are stored in the `.digest/` directory at the project root.

- **Directory**: `.digest/` (ensure this is gitignored)
- **Filename**: `YYYYMMDDHHMMSS_digest.md` (e.g., `20260422054014_digest.md`)

---

## Protocol

When `/swt:digest` is invoked, follow these steps:

### 1. Gather Context
- **Tasks**: Scan the `.tasks/` directory for files that are NOT `done` or `abandoned`.
- **Changes**: Check `git status` or `git diff --cached` to see what was modified.
- **Conversation**: Review the recent history to identify key outcomes, architectural decisions, and roadblocks.

### 2. Synthesize Outcomes
Identify the 3–5 most important achievements or decisions from the session. Focus on the *why* and the *impact*.

### 3. Identify Next Steps
Look at the active tasks and current conversation to determine the immediate priorities for the next session.

### 4. Write the Digest
Use the **Session Summary Template** below.

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
```

---

## Auto-Suggest Triggers

Proactively suggest `/swt:digest` when:
- The user says "goodbye", "talk to you later", or "done for now".
- After a successful `/swt:commit` that closes a major task.
- When shifting between significant context areas (e.g., from Frontend to Backend).

---

## Execution Layer

1. Get timestamp: `date +%Y%m%d%H%M%S`
2. Create `.digest/` directory if it doesn't exist.
3. Write the file.
4. Confirm to user: *"Session summary created: `.digest/YYYYMMDDHHMMSS_digest.md`. See you next time!"*
