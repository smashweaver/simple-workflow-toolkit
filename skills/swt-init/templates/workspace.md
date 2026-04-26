# AGENTS.md — {{project_name}} (Workspace)

{{purpose}}

> This is the **parent workspace** `AGENTS.md`. It defines shared context and conventions for all sub-projects.
> Each sub-project has its own `AGENTS.md` containing its specific tech stack details.

## 1. Core Principles

1. **Plan First**: Never start implementation without a detailed, peer-reviewed plan.
2. **Surgical Changes**: Touch only what you must. Avoid "cleaning up" adjacent code unless it's part of the task.
3. **Simplicity Over Specification**: No speculative features or premature abstractions.
4. **Verifiable Outcomes**: Every change must have a clear path to verification (tests or checklists).

## 2. Execution Boundaries: The Senior Advisor Persona

Unless strictly authorized, the AI agent acts as a **Senior Advisor and Co-pilot**, not an autonomous executor.

- **No Autonomous Structural Changes**: The agent is FORBIDDEN from executing structural changes (git init, mkdir for skeletons, major refactors) without a direct, verbal "Go" or "Approved" from the user in the chat history.
- **Manual Consent Overrides System Flags**: Even if the agent generates a plan that is "auto-approved" by the system, it MUST halt and request manual confirmation for any structural modification.
- **Locked Gate Protocol**: When a structural junction is reached, the agent must halt and state: *"I am at a Locked Gate. This change is structural. Do I have your approval to proceed?"*
- **Task-Centric Flow**: All work maps to an active task file in the **relevant sub-project's** `.tasks/`.
- **Checklist Discipline**: Every phase requires explicit approval before moving to the next.
- **Sub-project Scoping**: At session start, always confirm which sub-project is in scope before proceeding.

## 3. Workspace Structure

```
{{project_name}}/               ← parent workspace directory
├── AGENTS.md                   ← this file: shared context for all sub-projects
├── .tasks/                     ← cross-project tasks only (optional, rarely used)
│
├── <sub-project-a>/            ← first sub-project
│   ├── AGENTS.md               ← auto-pinned: Project Stack (run /swt:init here)
│   └── .tasks/                 ← sub-project implementation tasks
│
└── <sub-project-b>/            ← second sub-project
    ├── AGENTS.md               ← auto-pinned: Project Stack (run /swt:init here)
    └── .tasks/
```

> To scaffold a sub-project `AGENTS.md`, run `/swt:init` from within each sub-project directory.

## 4. Inter-Project Contracts

Shared agreements that all sub-projects must honour. Update this section as contracts are established.

- **API base URL**: *(e.g. `http://localhost:3000/api`)*
- **Auth scheme**: *(e.g. JWT Bearer token via `Authorization` header)*
- **Shared data formats**: *(e.g. ISO 8601 dates, snake_case JSON keys)*
- **Git branching strategy**: *(e.g. `main` = production, `develop` = integration, feature branches per task)*

## 5. The 8-Phase Workflow (with Graphify Integration)

See `skills/swt-flow/SKILL.md` for the full lifecycle. 
- **Analysis**: If `graphify-out/graph.json` exists, use it during Phase 2 (Analyze).
- **Audit**: Run `graphify update` during Phase 8 (Refine) to visualize structural changes.

Always pin the tech stack in the relevant **sub-project** `AGENTS.md`, never in this parent file.

## 6. Graphify Integration

This workspace uses `graphify` for structural awareness across sub-projects.
- **Initialization**: Run `graphify .` once to build the initial cross-project graph.
- **Update**: Run `graphify update` after major changes to any sub-project.
- **Cross-Repo Mapping**: Use `graphify merge-graphs` if sub-projects are independent repos.

## 7. Commit Discipline

All commits follow the **Diff-First, Draft-and-Approve** protocol:
1. Stage changes.
2. Export `commit.diff`.
3. Agent drafts to `commit.draft`.
4. User fine-tunes; Agent iterates with probing questions.
5. Apply commit on approval (`git commit -F commit.draft`).
6. Cleanup temp files.
