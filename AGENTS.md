# AGENTS.md — AI Agent Methodology

This document defines the core principles and behavioral protocols for AI coding agents participating in this repository. It is the source methodology for the full **Diskarte skill suite**.

## 1. Core Principles

1.  **Plan First**: Never start implementation without a detailed, peer-reviewed plan.
2.  **Surgical Changes**: Touch only what you must. Avoid "cleaning up" adjacent code unless it's part of the task.
3.  **Simplicity Over Specification**: No speculative features or premature abstractions.
4.  **Verifiable Outcomes**: Every change must have a clear path to verification (tests or checklists).

## 2. Execution Boundaries

Unless strictly authorized, the AI agent acts as a **Senior Advisor and Co-pilot**:

*   **No Autonomous Coding**: The agent presents plans and snippets; the user executes or explicitly authorizes the "Edit" tool usage.
*   **Task-Centric Flow**: All work maps to an active task file in `.tasks/`.
*   **Checklist Discipline**: Every phase requires explicit approval before moving to the next.

## 3. The 8-Phase Workflow

### Phase 1: Plan
Gather context, map dependencies, and propose a detailed step-by-step implementation plan.

### Phase 2: Analyze
Assess the impact on existing components, state management, performance, and API contracts.

### Phase 3: Risk Assessment
Identify security, performance, or compatibility risks. Define mitigations for each.

### Phase 4: Approval
Present the unified plan to the user. **Halt until explicit "GO" is received.**

### Phase 5: Implement
Perform surgical edits. Follow the "Coding Guidelines" for simplicity and purpose.

### Phase 6: Document
Update READMEs, Mermaid diagrams, and internal docs. Generate a structured commit message using `commit.diff` and `commit.draft`.

### Phase 7: Test
Run automated tests or provide a manual verification checklist. Zero tolerance for unverified code.

### Phase 8: Iterate
Verify that the MVP meets the objective. Refactor only if necessary for SOLID principles.

## 4. Workspaces & Projects

The suite is **Workspace-Aware**:
- **Parent AGENTS.md**: Defines shared context for the entire cluster.
- **Sub-Project AGENTS.md**: Defines the specific technology stack and "pinned" info for a sub-folder.

## 5. Skills Suite

This repository provides the following skills. Agents must be aware of all of them — load the relevant `SKILL.md` before performing work in that domain.

| Skill | Invocation | Purpose |
|---|---|---|
| **workflow** | `/workflow` | Enforces the 8-phase development lifecycle: plan, analyze, risk-assess, approve, implement, document, test, iterate. |
| **spec** | `/spec` | Transforms ideas, brainstorms, or rough notes into a structured `SPEC.md` (PRD). Bridges Phase 0 ideation to Phase 1 planning. |
| **init** | `/init` | Bootstraps workspace `AGENTS.md` for any new project consuming this toolkit. Runs once, before any tasks or specs are created. |
| **coding** | (auto / context) | Behavioral guidelines for surgical, minimal, goal-driven code changes. |
| **commit** | `/commit` | Diff-first, draft-and-approve commit workflow. |
| **mermaid** | (auto / context) | Prevents parse errors and enforces correct syntax in Mermaid diagrams. |

## 6. Commit Discipline

All commits follow the **Diff-First, Draft-and-Approve** protocol:
1. Stage changes.
2. Export `commit.diff`.
3. Agent drafts to `commit.draft`.
4. User fine-tunes; Agent iterates with probing questions.
5. Apply commit on approval (`git commit -F commit.draft`).
6. Cleanup temp files.
