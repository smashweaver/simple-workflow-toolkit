---
name: "swt:init"
description: >
  Use when setting up a new project or workspace that will consume the Simple Workflow Toolkit
  (SWT). Trigger when the user says things like "/swt:init", "bootstrap this
  project", "set up AGENTS.md", "initialize this workspace", or "I'm starting a
  new project with SWT". This skill runs ONCE per project at the very
  beginning, before any tasks or specs are created. It interviews the user to
  determine workspace type, loads the appropriate template, and scaffolds
  AGENTS.md. If AGENTS.md already exists, it runs in defensive diff mode —
  never overwrites blindly.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /swt:init — Workspace Bootstrap

You are initializing a new project workspace for the Simple Workflow Toolkit. Your job is to scaffold the correct `AGENTS.md` based on the workspace type, using a lean interview and template-loading approach. You are **defensive by default** — never overwrite an existing `AGENTS.md` without explicit user approval.

---

## Session-Start Protocol

> **This is the canonical definition.** The `/swt:flow` skill cross-references this section. Both skills enforce this protocol at the start of every session.

At the start of every session, **before doing anything else**:

1. **Read the root `AGENTS.md`** — understand the workspace context, project name, purpose, and any conventions defined there.
2. **Detect sub-projects** — scan for directories containing their own `AGENTS.md` or stack marker files (`package.json`, `pyproject.toml`, `go.mod`, `composer.json`, etc.).
3. **If multiple sub-projects are found**: Ask the user explicitly —
   > *"Which sub-project are we focusing on today? [list sub-project names]"*
   — before proceeding with any task.
4. **If only one project context**: Orient silently and proceed.
5. **Summarise** what you've understood: workspace name, active sub-project (if any), and any open tasks found in `.tasks/`.

> ⚠️ If no `AGENTS.md` exists in the workspace root, prompt the user:
> *"This workspace has no `AGENTS.md`. Would you like to run `/swt:init` to bootstrap one before we begin?"*

---

## Invocation Flow

```
/swt:init is invoked
  │
  ├─ AGENTS.md exists at workspace root?
  │     ├─ YES → [Diff Mode]      ── see "Defensive Diff Protocol" below
  │     └─ NO  → [Interview Mode] ── see "Interview" below
  │
  └─ On completion: confirm what was created or changed, and what to do next
```

---

## Interview Mode

Ask all three questions in a **single message** — never one at a time.

> "To scaffold the right `AGENTS.md` for your workspace, I need three quick answers:"
>
> **1 — Workspace type** *(determines which template to use)*
> - **Single-project** — one codebase at the root (e.g. a standalone app, API, or script)
> - **Multi-project** — multiple sub-projects under a shared parent (e.g. frontend + backend)
> - **Toolkit** — a skills or tooling repository (e.g. Simple Workflow Toolkit itself)
>
> **2 — Project name**
> What is the name of this project or workspace?
>
> **3 — Purpose**
> In one or two sentences, what is its purpose?

After receiving answers:

1. Load the matching template from `skills/swt-init/templates/` (see **Template Loading** below).
2. Substitute `{{project_name}}` and `{{purpose}}` with the user's answers.
3. Write `AGENTS.md` to the workspace root.
4. Confirm to the user and suggest the next step.

> 💡 Stack detection is deliberately left to the `/swt:flow` skill's auto-pin mechanism. Do not ask about the tech stack here.

---

## Template Loading

| User Answer    | Template file                               |
|----------------|---------------------------------------------|
| Single-project | `skills/swt-init/templates/single-project.md`   |
| Multi-project  | `skills/swt-init/templates/multi-project.md`    |
| Toolkit        | `skills/swt-init/templates/toolkit.md`          |

Read the template file, substitute the two placeholders, then write to `./AGENTS.md` at the workspace root.

**Placeholders:**
- `{{project_name}}` — replaced with the user's answer to Q2
- `{{purpose}}` — replaced with the user's answer to Q3

---

## Defensive Diff Protocol

When `AGENTS.md` already exists at the workspace root, **do not modify it until explicitly approved.**

### Step 1 — Ask which template to compare against

> *"An `AGENTS.md` already exists. Which template should I compare it against to identify what's missing or unexpected?"*
> 1. Single-project
> 2. Multi-project
> 3. Toolkit

### Step 2 — Parse the existing file

Scan for the presence of these known section headers:

- `## Core Principles`
- `## Execution Boundaries`
- `## The 8-Phase Workflow` (or `## Workflow`)
- `## Skills Suite`
- `## Project Stack`
- `## Workspace Structure`
- `## Inter-Project Contracts`
- `## Commit Discipline`

### Step 3 — Present a semantic diff table

Display the result as a comparison table:

```
Section                     | In your file | Expected by template
----------------------------|:------------:|:---------------------:
## Core Principles          |      ✅      | ✅ required
## Execution Boundaries     |      ✅      | ✅ required
## Skills Suite             |      ❌      | ✅ required
## Commit Discipline        |      ✅      | ✅ required
## Project Stack            |      ✅      | ⚠️  not expected here
```

**Legend:**
- `✅` — present and expected
- `❌` — missing; will be **appended** if approved
- `⚠️` — present but not expected by selected template; flagged only, **never auto-removed**

### Step 4 — Propose specific actions

List each action clearly:

- *"I will append `## Skills Suite` to your existing file."*
- *"I found `## Project Stack` — the toolkit template does not expect this section. I'll leave it as-is unless you tell me to remove it."*

### Step 5 — Hard stop (MANDATORY)

> *"Shall I apply these changes?"*

**Do not write or edit anything until the user explicitly confirms.**

### Step 6 — Apply (on confirmation only)

Make targeted appends or edits using Edit — **never rewrite the entire file.** Preserve all existing content the user has written.

---

## Post-Init Checklist

After successfully writing or updating `AGENTS.md`, confirm to the user:

- [ ] `AGENTS.md` created or updated at workspace root
- [ ] `{{project_name}}` and `{{purpose}}` are filled in (no raw placeholders remain)
- [ ] **Multi-project only**: Remind the user that each sub-project also needs its own `AGENTS.md`. They can run `/swt:init` again from within each sub-project directory, or create the files manually.
- [ ] Suggest the next step: *"Your workspace is bootstrapped. Run `/swt:flow` and describe your first task to begin."*
