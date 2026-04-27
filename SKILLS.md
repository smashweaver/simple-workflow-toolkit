# SWT Skills Catalog

The Simple Workflow Toolkit is a suite of AI agent skills that enforce disciplined, consent-gated software development. Install it into any project and every session follows a structured workflow — from initial idea to verified commit.

> **Agent Behavior Note**: Before creating any file or task, your agent will always propose a name and wait for your confirmation. You stay in control of every decision.

## Skill Categories

Based on their purposes and triggers:

### Planning & Design
- **swt:spec**: Turns ideas into structured PRDs/specs.
- **swt:think**: Base behavioral guidelines for reasoning in non-coding tasks.

### Workflow & Task Management
- **swt:flow**: Enforces 8-phase development lifecycle.
- **swt:task**: Manages task lifecycle (creation, graduation, status).
- **swt:status**: Aggregates project state for session restoration.

### Implementation & Coding
- **swt:code**: Guidelines for surgical, minimal code changes.
- **swt:graphify**: Structural awareness and dependency mapping (Opt-in).

### Version Control & Commits
- **swt:commit**: Diff-first, draft-and-approve commit workflow.

### Initialization & Setup
- **swt:init**: Bootstraps projects with AGENTS.md and scaffolding.
- **swt:link**: Manages symlinks for skill discovery.

### Documentation & Visualization
- **swt:mermaid**: Ensures correct syntax in Mermaid diagrams.

### Session Continuity
- **swt:digest**: Automates structured session summaries.

---

## How Skills Work Together

The skills are designed to work in sequence. Here is the typical lifecycle of a feature from idea to commit:

```mermaid
flowchart TD
    A["/swt:task brainstorm\nPhase 0: Ideate"] --> B["/swt:task graduate\nPromote to Phase 1"]
    B --> C["/swt:flow\nPlan, Analyze, Approve"]
    C --> D["Implement\nguided by /swt:code"]
    D --> E["/swt:flow (Phase 8)\nReview & Refine"]
    E --> F["/swt:commit\nDraft & Approve"]
    F --> G["/swt:digest\nSave summary"]
    
    subgraph "Structural Awareness (Opt-in)"
    H["/swt:graphify query\nPhase 2: Analyze"] -.-> C
    I["/swt:graphify update\nPhase 8: Refine"] -.-> E
    end
```

---

## 🧠 Base Behavioral Skills

### `/swt:think` — Reasoning Guidelines

Base behavioral guidelines for all AI agent reasoning. **All other SWT skills inherit from this skill.**

Provides the core principles (Think, Brevity, Focus, Clear Success Criteria) that `swt:code`, `swt:digest`, `swt:task`, `swt:spec`, `swt:init`, and `swt:commit` adapt for their specific contexts.

**When to use**: This skill loads automatically as the base layer when any generation skill is triggered. Agents apply these principles to all non-coding reasoning tasks.

---

## 🛠️ Core Management Skills

### `/swt:flow` — Workflow Enforcer

Guides you through the full 8-phase development lifecycle with mandatory consent gates. The agent acts as a **Senior Advisor** — it presents plans, analyzes risks, and waits for your approval before writing any code.

**When to use**: Before starting any non-trivial feature or change.

**Key consent gates**:
- **Gate 2**: Agent presents the full plan and waits for your explicit "GO" before implementation.
- **Gate 4**: Agent pauses after the MVP works and waits for your review before finalizing.

```
/swt:flow
```

---

### `/swt:task` — Task Manager

Owns the full task lifecycle: creation, brainstorming, graduation, status tracking, and cleanup. All work is tracked in a `.tasks/` directory at the project root.

**Key commands**:

| Command | Purpose |
|---|---|
| `/swt:task new` | Create a standard implementation task (Phase 1) |
| `/swt:task brainstorm` | Create a Phase 0 ideation task for exploratory thinking |
| `/swt:task graduate` | Promote a brainstorm task to an implementation task |
| `/swt:task list --open` | Show all active tasks |
| `/swt:task update` | Mark a phase complete and advance to the next |
| `/swt:task close` | Mark a task as done or abandoned |
| `/swt:task --tidy` | Archive completed tasks into `.tasks/archive/` |

---

### `/swt:init` — Workspace Bootstrap

Scaffolds an `AGENTS.md` file for any new project consuming SWT. Establishes shared conventions and auto-detects the technology stack.

**When to use**: Once, at the very start of a new project.

```
/swt:init
```

Automatically generates or updates **`GEMINI.md`** and **`CLAUDE.md`** discovery pointers at the project root. These shims redirect agents to the `AGENTS.md` source of truth for all behavioral rules and workflow protocols.

---

### `/swt:link` — Skill Linker

Creates or refreshes symlinks to install SWT skills into agent discovery paths (`.claude/`, etc.). Supports dogfooding live changes across multiple agents.

**When to use**: After adding a new skill or setting up a new development environment.

```
/swt:link              # Link into the current project
/swt:link --global     # Link globally (~/.claude)
/swt:link /path        # Link into a specific directory
```

---

## 📝 Ideation & Documentation Skills

### `/swt:spec` — Specification Generator

Transforms rough ideas, brainstorms, or notes into a structured `SPEC.md` (Product Requirements Document). Bridges free-form thinking to a formal implementation plan before any code is written.

**When to use**: When you have a big idea that needs structure before creating a task.

```
/swt:spec
```

---

### `/swt:digest` — Session Continuity Manager

Creates structured session summaries so the next agent session picks up exactly where you left off. Eliminates context drift between sessions.

**When to use**: At the end of a session, or after a major milestone.

| Command | Purpose |
|---|---|
| `/swt:digest` | Standard session summary (last 5 sessions) |
| `/swt:digest --milestone` | Full project roll-up since the last milestone |

**Auto-triggers**: Say *"goodbye"*, *"done for now"*, or *"talk to you later"* and the agent will suggest running a digest automatically.

---

## 🔍 Structural Awareness Skills

### `/swt:graphify` — Project Graph Orchestrator

The "Eyes" of the toolkit. A thin wrapper for the **graphify** engine that provides structural awareness during the development workflow. It helps the agent (and you) understand the architectural "Big Picture" and surfaces risk by identifying central "God Nodes" and hidden bridges between communities.

| Command | Purpose |
|---|---|
| `/swt:graphify verify` | Check for engine presence in system PATH |
| `/swt:graphify on / off` | Explicitly enable/disable structural rituals |
| `/swt:graphify status` | Check current state and artifact presence |
| `/swt:graphify init` | Perform a full project build (deep scan) |
| `/swt:graphify query "<text>"` | Semantic search for Phase 2: Analyze |
| `/swt:graphify update` | Incremental update for Phase 8: Review |
| `/swt:graphify explain "<node>"` | Structural breakdown of a component |


**When to use**: Enable it on complex projects where understanding hidden dependencies and architectural drift is critical.

---

### `/swt:mermaid` — Diagram Syntax Guard

Prevents Mermaid diagram parse errors by enforcing correct syntax rules before writing any diagram.

**When to use**: Applied automatically whenever your agent writes a Mermaid diagram. No manual invocation needed.

---

## 💻 Execution & Quality Skills

### `/swt:code` — Coding Guidelines

Enforces surgical, minimal, goal-driven code changes. Prevents scope creep, unnecessary refactors, and speculative features.

**Inherits from `/swt:think`** — the base behavioral guidelines for all AI agent reasoning. This skill adapts those principles specifically for coding tasks.

**This is a behavioral skill** — your agent applies these guidelines automatically during every implementation phase.

**Core principles**:
- Touch only what the task requires.
- No cleanup of adjacent code unless explicitly authorized.
- No speculative features or premature abstractions.
- Every change must have a clear path to verification.

---

### `/swt:commit` — Commit Workflow

Enforces a "Diff-First, Draft-and-Approve" commit protocol. Your agent **never commits autonomously** — every commit is reviewed and approved by you before it is applied.

**How it works**:
1. Stage your changes.
2. Agent exports a `commit.diff` and drafts a human-readable `commit.draft`.
3. You review and fine-tune the message.
4. Agent applies the commit only after your explicit approval.
5. Temp files are cleaned up automatically.

```
/swt:commit
```

---

*For the internal development protocol — Locked Gates, dogfooding rituals, and agent enforcement logic — see [AGENTS.md](./AGENTS.md).*
