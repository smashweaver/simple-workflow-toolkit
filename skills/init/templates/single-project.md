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

## 3. The 8-Phase Workflow

See `skills/workflow/SKILL.md` for the full lifecycle.

| Phase | Purpose |
|---|---|
| 1. Plan | Gather context, map dependencies, propose a step-by-step plan |
| 2. Analyze | Assess impact on components, state, performance, and contracts |
| 3. Risk Assessment | Identify risks with mitigations |
| 4. Approval | Present the complete plan — do not proceed without explicit user approval |
| 5. Implement | Surgical edits, one file at a time, with explanations |
| 6. Document | Update docs, diagrams, generate commit messages |
| 7. Test | Run tests or provide manual verification checklists |
| 8. Iterate | Verify MVP works, then refactor for maintainability |

## 4. Project Stack

<!-- To be auto-detected and populated by the /workflow skill on first use. -->
<!-- Do not edit manually unless the stack has changed. -->

## 5. Commit Discipline

All commits follow the **Diff-First, Draft-and-Approve** protocol:
1. Stage changes.
2. Export `commit.diff`.
3. Agent drafts to `commit.draft`.
4. User fine-tunes; Agent iterates with probing questions.
5. Apply commit on approval (`git commit -F commit.draft`).
6. Cleanup temp files.
