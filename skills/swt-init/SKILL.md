---
name: "swt:init"
description: >
  Use when setting up a new project or workspace that will consume the Simple Workflow Toolkit
  (SWT). Trigger when the user says things like "/swt:init", "bootstrap this
  project", "set up AGENTS.md", "initialize this workspace", or "I'm starting a
  new project with SWT". This skill runs ONCE per project at the very
  beginning, before any tasks or specs are created. It interviews the user to
  determine workspace type, loads the appropriate template, and scaffolds
  AGENTS.md. For workspaces, it also initializes directory structures.
  **Mandatory Phase 0**: Since this is a structural change, a Phase 0 brainstorm
  (Scenario A, B, C) MUST be presented and approved before execution.
  If AGENTS.md already exists, it runs in defensive diff mode — never overwrites blindly.
  Supports `--claude` flag to generate a CLAUDE.md shim for Claude Code users
  (opt-in only, never the default).
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

1. **Read the latest session digest** in `.digests/` — understand the previous agent's outcomes and strategic intent. Use `bash ls` + `read` (NOT glob/search tools) since these directories are gitignored.
2. **Read the root `AGENTS.md`** — understand the workspace context, project name, purpose, and any conventions defined there.
3. **Detect sub-projects** — scan for directories containing their own `AGENTS.md` or stack marker files (`package.json`, `pyproject.toml`, `go.mod`, `composer.json`, etc.).
4. **If multiple sub-projects are found**: Ask the user explicitly —
   > *"Which sub-project are we focusing on today? [list sub-project names]"*
   — before proceeding with any task.
5. **If only one project context**: Orient silently and proceed.
6. **Summarise** what you've understood: workspace name, active sub-project (if any), and any open tasks found in `.tasks/`.

> ⚠️ If no `AGENTS.md` exists in the workspace root, prompt the user:
> *"This workspace has no `AGENTS.md`. Would you like to run `/swt:init` to bootstrap one before we begin?"*

---

## Flag Reference

| Flag | Default | Description |
|------|---------|-------------|
| `--claude` | off | Generate a `CLAUDE.md` shim alongside `AGENTS.md`. Claude Code natively reads `CLAUDE.md` at session start. This flag is opt-in only. |
| `--no-claude` | — | Explicitly skip `CLAUDE.md` generation (redundant unless aliased). |

### CLAUDE.md Behavior

- **No existing `CLAUDE.md`**: Creates a thin shim that points to `AGENTS.md`.
- **Existing `CLAUDE.md`, no SWT directive**: Prepends an `<!-- SWT DIRECTIVE -->` block (idempotent, never overwrites user content).
- **Existing `CLAUDE.md`, SWT directive present**: Skips silently (idempotent).

---

## Invocation Flow

```
/swt:init [--claude] is invoked
  │
  ├─ AGENTS.md exists at workspace root?
  │     ├─ YES ──
  │     │         ├─ --claude? ── [Retrofit Mode]  ── see below
  │     │         └─ no flag  ── [Diff Mode]      ── see "Defensive Diff Protocol"
  │     └─ NO  ── [Interview Mode] ── see "Interview" below
  │                └─ if --claude: also generate CLAUDE.md shim
  │
  └─ On completion: confirm what was created or changed, and what to do next
```

---

## Interview Mode

### Smart Detection

Before asking the user, the agent should attempt to infer the workspace type:
- **Workspace**: If the current directory contains subdirectories with `AGENTS.md` or stack markers (e.g., `package.json`, `pyproject.toml`).
- **Single**: If the directory is empty or contains only a single project's files.

### The Prompt

Ask all questions in a **single message**. Pre-select the default based on smart detection.

> "To scaffold the right `AGENTS.md` for your workspace, I need three quick answers:"
>
> **1 — Workspace type**
> - **Single** [default] — one codebase at the root (standalone app, API, etc.)
> - **Workspace** — a container for multiple independent repos (e.g., frontend + backend)
>
> **2 — Project name**
> What is the name of this project or workspace?
>
> **3 — Purpose**
> In one or two sentences, what is its purpose?

After receiving answers:

1. Load the matching template from `skills/swt-init/templates/`.
2. Substitute `{{project_name}}` and `{{purpose}}` placeholders.
3. If **Workspace**, perform **Workspace Scaffolding** (see below).
4. Write `AGENTS.md` to the workspace root.
5. If `--claude` flag was passed, generate `CLAUDE.md` shim (see "CLAUDE.md Generation" below).
6. Confirm to the user and suggest the next step.

> 💡 Stack detection is deliberately left to the `/swt:flow` skill's auto-pin mechanism. Do not ask about the tech stack here.

---

## Template Loading

| User Answer | Template file                       |
|-------------|-------------------------------------|
| Single      | `skills/swt-init/templates/single-project.md` |
| Workspace   | `skills/swt-init/templates/workspace.md`      |

Read the template file, substitute the two placeholders, then write to `./AGENTS.md` at the workspace root.

**Placeholders:**
- `{{project_name}}` — replaced with the user's answer to Q2
- `{{purpose}}` — replaced with the user's answer to Q3

---

## Workspace Scaffolding

When the type is **Workspace**, the agent must also perform these actions if they haven't been done:

1. **Git Init**: Run `git init` to version the workspace meta-files.
2. **.gitignore**: Create a `.gitignore` with:
   - `.tasks/` (unless tasks are intended to be shared via git)
   - Sub-project directory names (to prevent them being treated as submodules)
   - Common OS/IDE cruft (`.DS_Store`, `.vscode/`, etc.)
3. **Task Directory**: `mkdir -p .tasks/` to store cross-project tasks.
4. **README**: Create a `README.md` skeleton with the project name and purpose.

---

## Defensive Diff Protocol

When `AGENTS.md` already exists at the workspace root, **do not modify it until explicitly approved.**

### Step 1 — Ask which template to compare against

> *"An `AGENTS.md` already exists. Which template should I compare it against to identify what's missing or unexpected?"*
> 1. Single
> 2. Workspace

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

> [!IMPORTANT]
> Because `swt:init` performs structural changes (git init, mkdir, file creation), you MUST request explicit verbal approval even if system auto-approval is on.

> *"Shall I apply these structural changes? (This requires your explicit verbal 'Go' in chat)"*

**Do not write or edit anything until the user explicitly confirms.**

### Step 6 — Apply (on confirmation only)

Make targeted appends or edits using Edit — **never rewrite the entire file.** Preserve all existing content the user has written.

---

## Retrofit Mode (--claude + existing AGENTS.md)

When `/swt:init --claude` is invoked and `AGENTS.md` already exists, do NOT run the Defensive Diff Protocol. Instead:

1. **Leave `AGENTS.md` untouched** — retrofit mode only adds `CLAUDE.md`.
2. **Handle `CLAUDE.md`** (see "CLAUDE.md Generation" below).
3. **Confirm** what was done:
   > *"Retrofit complete. `AGENTS.md` was left unchanged. `CLAUDE.md` was [created|updated] at [path]."*

---

## CLAUDE.md Generation

Shared logic for generating or updating `CLAUDE.md`. Called from Interview Mode (if `--claude`) or Retrofit Mode.

### Step 1 — Check if CLAUDE.md exists

```bash
if [[ -f "CLAUDE.md" ]]; then
  # Exists — check for existing SWT directive
else
  # New file — create shim
fi
```

### Step 2 — New file (no existing CLAUDE.md)

Write a thin shim to `./CLAUDE.md`:

```markdown
# CLAUDE.md
# Auto-generated by swt:init --claude — do not edit directly.
# All behavioral rules, workflow protocols, and project context are defined in AGENTS.md.
# Read it at the start of every session.

See AGENTS.md for full methodology.
```

### Step 3 — Existing file (CLAUDE.md present)

1. Read the file.
2. Check if `<!-- BEGIN SWT DIRECTIVE` is already present.
   - **Yes** → Skip silently (idempotent).
   - **No** → **Prepend** the SWT directive block at the top of the file.

**SWT Directive Block:**

```markdown
<!-- BEGIN SWT DIRECTIVE — added by swt:init --claude -->
## SWT Integration
This project uses the Simple Workflow Toolkit. All behavioral rules and workflow
protocols are defined in AGENTS.md. Read it at the start of every session.
<!-- END SWT DIRECTIVE -->

```

**Prepend logic**: Insert the directive block before the first line of the existing file, preserving all original content.

### Step 4 — Confirm

> *"`CLAUDE.md` [created|updated] at [path]. It now references AGENTS.md for session startup."*

---

## Post-Init Checklist

After successfully writing or updating `AGENTS.md`, confirm to the user:

- [ ] `AGENTS.md` created or updated at workspace root
- [ ] `{{project_name}}` and `{{purpose}}` are filled in (no raw placeholders remain)
- [ ] **If `--claude`**: `CLAUDE.md` created/updated at workspace root (or SWT directive prepended to existing file)
- [ ] **Workspace only**: Remind the user that each sub-project also needs its own `AGENTS.md`. They can run `/swt:init` again from within each sub-project directory.
- [ ] Suggest the next step: *"Your workspace is bootstrapped. Run `/swt:flow` and describe your first task to begin."*

---

## Companion Skill

This skill **inherits from `swt:think`** (`skills/swt-think/SKILL.md`), which provides base behavioral principles for all AI agent reasoning. This skill adapts those principles specifically for workspace bootstrapping and AGENTS.md generation.
