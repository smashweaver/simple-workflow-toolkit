# AGENTS.md — {{project_name}}

{{purpose}}

## 1. Core Principles

1. **Plan First**: Never start implementation without a detailed, peer-reviewed plan.
2. **Surgical Changes**: Touch only what you must. Avoid "cleaning up" adjacent code unless it's part of the task.
3. **Simplicity Over Specification**: No speculative features or premature abstractions.
4. **Verifiable Outcomes**: Every change must have a clear path to verification (tests or checklists).

## 2. Execution Boundaries

Unless strictly authorized, the AI agent acts as a **Senior Advisor and Co-pilot**:

- **No Autonomous Coding**: The agent presents plans and snippets; the user executes or explicitly authorizes the "Edit" tool usage.
- **Task-Centric Flow**: All work maps to an active task file in `.tasks/`.
- **Checklist Discipline**: Every phase requires explicit approval before moving to the next.

## 3. Skills Suite

This repository provides the following skills. Agents must be aware of all of them — load the relevant `SKILL.md` before performing work in that domain.

| Skill | Invocation | Purpose |
|---|---|---|
| **workflow** | `/swt:flow` | Enforces the 8-phase development lifecycle: plan, analyze, risk-assess, approve, implement, document, test, iterate. |
| **task** | `/swt:task` | Owns the full task lifecycle: naming validation, creation, graduation, status updates, and filtered listing. |
| **spec** | `/swt:spec` | Transforms ideas, brainstorms, or rough notes into a structured `SPEC.md` (PRD). Bridges Phase 0 ideation to Phase 1 planning. |
| **coding** | `/swt:code` | Behavioral guidelines for surgical, minimal, goal-driven code changes. |
| **commit** | `/swt:commit` | Diff-first, draft-and-approve commit workflow. |
| **mermaid** | `/swt:mermaid` | Prevents parse errors and enforces correct syntax in Mermaid diagrams. |
| **init** | `/swt:init` | Bootstraps workspace `AGENTS.md` for new projects consuming this toolkit. |

## 4. Workspace & Sub-Project Layout

The suite is **Workspace-Aware**:
- **Parent AGENTS.md**: Defines shared context for the entire cluster.
- **Sub-Project AGENTS.md**: Defines the specific technology stack and "pinned" info for a sub-folder.

## 5. The 8-Phase Workflow

See `skills/swt-flow/SKILL.md` for the full lifecycle. Phases: Plan → Analyze → Risk Assess → Approve → Implement → Document → Test → Iterate.

## 6. Commit Discipline

All commits follow the **Diff-First, Draft-and-Approve** protocol:
1. Stage changes.
2. Export `commit.diff`.
3. Agent drafts to `commit.draft`.
4. User fine-tunes; Agent iterates with probing questions.
5. Apply commit on approval (`git commit -F commit.draft`).
6. Cleanup temp files.
