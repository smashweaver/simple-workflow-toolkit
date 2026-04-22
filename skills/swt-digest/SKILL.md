---
name: "swt:digest"
description: >
  Automates the creation of structured session summaries for continuity.
  Trigger at the end of a session, after a major milestone, or when the user
  asks for a summary. Stores timestamped files in `.digests/`.
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
- **Filename**: `YYYYMMDDHHMMSS_digest.md` (e.g., `20260422054014_digest.md`)

---

## Protocol

When `/swt:digest` is invoked, follow these steps:

### 1. Gather Context
- **Previous Digests (Window of 5)**: List the last 5 files in `.digests/` (e.g., `ls -1 .digests/*_digest.md | tail -n 5`).
- **Deep History Retrieval**: If a current digest lists a parent in `.digests/archive/` that you need to examine for more detail, do not hesitate to read it. The archive is your "Long-Term Memory."
- **Redundancy Filtering**: Analyze the headers of these files. If Digest B lists Digest A as a "Synthesized Parent," Digest A is redundant.
- **Orphan Capture**: Read the content of any "orphaned" digests (not accounted for by successors) plus the latest digest to ensure 100% detail retention.
- **Tasks**: Scan the `.tasks/` directory for files that are NOT `done` or `abandoned`.
- **Changes**: Check `git status` or `git diff --cached` to see what was modified.
- **Conversation**: Review recent history and the identified previous digests to identify key outcomes, architectural decisions, and roadblocks.

### 2. Synthesize Outcomes
Identify the 3–5 most important achievements or decisions from the session. Focus on the *why* and the *impact*. **Recursive Awareness**: Carry forward any critical architectural decisions from the previous digest that remain relevant.

### 3. Identify Next Steps
Look at the active tasks, current conversation, and the "Next Steps" from the previous digest. If previous steps are still unresolved, carry them forward or update them to reflect new priorities.

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

## Synthesized Parent Digests

- .digests/archive/{{Filename of synthesized digest 1}}
- .digests/archive/{{Filename of synthesized digest 2}}
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
2. Create `.digests/` directory if it doesn't exist.
3. Scan last 5 digests: `ls -1 .digests/*_digest.md 2>/dev/null | tail -n 5`
4. Analyze headers and read "orphaned" + latest digests to synthesize the "Chain of Truth".
5. Write the file.
6. **Archive parents**: Move all files listed in "Synthesized Parent Digests" to `.digests/archive/`.
7. Confirm to user: *"Session summary created: `.digests/YYYYMMDDHHMMSS_digest.md`. (Archived {{N}} parents). See you next time!"*
