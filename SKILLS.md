# SWT Skills Catalog

The Simple Workflow Toolkit is a suite of AI agent skills that enforce disciplined, consent-gated software development. Install it into any project and every session follows a structured workflow — from initial idea to verified commit.

> **Agent Behavior Note**: Before creating any file or task, your agent will always propose a name and wait for your confirmation. You stay in control of every decision.

## Skill Categories

Based on their purposes and triggers:

### Planning & Design
- **swt:spec**: Turns ideas into structured PRDs/specs.
- **swt:think**: Base behavioral guidelines for reasoning in non-coding tasks.

### Workflow & Task Management
- **swt:flow**: Enforces 8-phase development lifecycle. Acts as the **Unified Facade** for all toolkit functionality.
- **swt:task** — Owns the lifecycle of task files. Enforces naming rules, provides templates, handles Phase 0 graduation, and automates root artifact cleanup upon closure.
- **swt:status**: Aggregates project state for session restoration.

### Implementation & Coding
- **swt:code**: Guidelines for surgical, minimal code changes.
- **swt:graphify**: Structural awareness and dependency mapping (Opt-in).

### Version Control & Commits
- **swt:commit**: Diff-first, draft-and-approve commit workflow.

### Initialization & Setup
- **swt:init**: Bootstraps projects with AGENTS.md and discovery pointers.
- **swt:link**: Manages symlinks for skill discovery.

### Documentation & Visualization
- **swt:mermaid**: Ensures correct syntax in Mermaid diagrams.

### Session Continuity
- **swt:digest**: Automates structured session summaries.

---

## How Skills Work Together

The Simple Workflow Toolkit uses an **Orchestrator Pattern** to unify the user experience. All high-level commands are routed through the `/swt:flow` facade, ensuring consistent methodology enforcement across all project operations.

→ **[See ARCHITECTURE.md](./ARCHITECTURE.md)** for detailed inheritance diagrams and structural rationale.

---

## 🧠 Base Behavioral Skills

### `/swt:think` — Reasoning Guidelines

Base behavioral guidelines for all AI agent reasoning. **All other SWT skills inherit from this skill.**

**When to use**: This skill loads automatically as the base layer when any generation skill is triggered. Agents apply these principles to all non-coding reasoning tasks.

---

## 🛠️ Core Management Skills

### `/swt:flow` — Unified Orchestrator

The primary "Command Center" for the toolkit. It unifies all specialized skills under a developer-aligned interface.

**Key Commands**:
| Command | Purpose | Skill |
|---|---|---|
| `/swt:flow status` | Workspace summary | `swt:status` |
| `/swt:flow pulse` | Status + Git history (Heartbeat) | `swt:status` |
| `/swt:flow backlog` | Show all open/active tasks | `swt:task` |
| `/swt:flow history` | Show complete project timeline | `swt:task` |
| `/swt:flow context` | Show current active task path | `swt:task` |
| `/swt:flow audit` | Deep ritual integrity check | `swt:task` |
| `/swt:flow commit` | Start commit ritual | `swt:commit` |
| `/swt:flow digest` | Create session summary | `swt:digest` |
| `/swt:flow symlink` | Global dev setup (--global --clear) | `swt:link` |
| `/swt:flow query` | Semantic structural search | `swt:graphify` |

---

### `/swt:task` — Task Manager

Owns the full task lifecycle: creation, brainstorming, graduation, status tracking, and cleanup. All work is tracked in a `.tasks/` directory at the project root.

**Key commands**:

| Command | Purpose |
|---|---|
| `/swt:task new` | Create a standard implementation task (Phase 1) |
| `/swt:task brainstorm` | Create a Phase 0 ideation task |
| `/swt:task graduate` | Promote a brainstorm task to Phase 1 (+ Spec) |
| `/swt:task phase <N>` | Manual ritual phase transition (Signed Log) |
| `/swt:task mount <file>` | Set active task context (`task.ctx`) |
| `/swt:task audit` | Deep protocol and ritual integrity audit |
| `/swt:task close <hash>` | Finalize a task as done (hash required) |
| `/swt:task bug` | Report toolkit friction to SWT core (Upstream) |

---

### `/swt:init` — Workspace Bootstrap

Scaffolds an `AGENTS.md` file for any new project consuming SWT. Establishes shared conventions and auto-detects the technology stack.

**When to use**: Once, at the very start of a new project.

```
/swt:init
```

---

### `/swt:link` — Skill Linker

Creates or refreshes symlinks to install SWT skills into agent discovery paths (`.claude/`, etc.).

```
/swt:link              # Link into the current project
/swt:link --global     # Link globally (~/.agents)
/swt:link --clear      # Remove existing links first
```

---

*For the full internal development protocol — Locked Gates, dogfooding rituals, and agent enforcement logic — see [AGENTS.md](./AGENTS.md).*
