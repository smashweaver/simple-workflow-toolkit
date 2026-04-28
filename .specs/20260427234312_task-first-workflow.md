# Spec: task-first-workflow
**Version**: 0.1
**Status**: draft
**Linked Task**: .tasks/20260427184057_task-first-workflow.md

## 1. Problem Statement

AI agents (Claude, opencode, etc.) read AGENTS.md but don't act on workflow rules without explicit user commands. This leads to "vibecoding" — untracked problem-solving where users raise issues mid-session and agents start coding without creating task files. Work is lost across sessions because there's no persistent task context linking conversations together.

## 2. Goals

- Route all work through the SWT task lifecycle (create → graduate → implement)
- Persist active task context across sessions and agent switches
- Guide users to create brainstorm tasks when new topics arise mid-session
- Prevent coding outside of swt:flow phases
- SPEC is populated and finalized BEFORE Phase 2+ (source of truth for implementation)

## 3. Proposed Solution

Introduce `task.ctx` — a single-line file in the project root containing the active task filename. Back it with:

**Scenario A (Discipline)** — Methodology-only, no scripts:
- Update AGENTS.md Section 7 to mandate `task.ctx` check at session start
- Update `swt:think` with Task-First Workflow rule
- Agents manually check and guide users to create tasks

**Scenario B (Automation)** — Helper scripts, not mandatory:
- `swt.sh ctx set/clear/show` commands in task.sh
- `flow.sh` — active engine with open/check/status commands
- `task.ctx` auto-clears on `task.sh close`
- Updates to swt:status, swt:digest to display active context

**Scenario C (Enforcement)** — Hard gates, physical blocks:
- `task.sh validate` blocks Phase 5+ if no active `task.ctx`
- Scripts enforce SPEC-first rule (no Phase 2+ without populated SPEC)

Selected approach: **Hybrid B+C** — automation via scripts (B) with validation gates (C), but no aggressive keyword matching.

## 4. User Stories

- [x] US-001: As an agent, I can read `task.ctx` at session start and immediately know what task is active
- [x] US-002: As a user, when I raise a new issue mid-session, the agent asks if I want a brainstorm task created
- [x] US-003: As an agent, I refuse to code outside swt:flow phases — I guide the user to create a task first
- [x] US-004: As a user switching agents (Claude → opencode), the new agent picks up the same task context automatically
- [x] US-005: As an agent, when a task is closed, I automatically clear `task.ctx`
- [x] US-006: As an agent, I cannot proceed to Phase 2+ without a fully populated SPEC

## 5. Non-Functional Requirements

- `task.ctx` must be gitignored (not committed to repo)
- All context reads/writes must handle stale references (task file deleted/moved)
- Scripts must work from subdirectories (workspace root detection via AGENTS.md/.git)
- SPEC must be populated immediately after graduation (before Phase 2+)

## 6. Implementation Plan

1. Add `task.ctx` to `.gitignore`
2. Fix `task.sh graduate` to populate SPEC from task's Core Concept, Explored Alternatives, and Notes
3. Add `ctx set/clear/show` commands to `task.sh` + hook into `phase`/`close`
4. Create `flow.sh` with `open`/`check`/`status` commands
5. Update `status.sh` to display active `task.ctx` at top of output
6. Add Task-First Rule to `swt:think` (session start, midstream topic shifts, coding gate)
7. Add `task.ctx` awareness to `digest.sh`
8. Update `swt-flow/SKILL.md` Session-Start Protocol with `task.ctx` check
9. Update `AGENTS.md` Section 7 with `task.ctx` step
10. Add SPEC-First Rule to Phase 1 in both `swt-flow/SKILL.md` and `AGENTS.md`
11. **Formalize SPEC structure in `swt:spec`**: Replace 16-section template in `SKILL.md` (lines 89-250) with the 12-section structure used here (Problem Statement, Goals, Proposed Solution, User Stories, Non-Functional Requirements, Implementation Plan, Risks & Mitigations, Success Criteria, Out of Scope, Open Questions, References, MVP Definition)

## 7. Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| `task.ctx` points to deleted/moved task | Low | `flow.sh open` validates file existence before loading; clear stale ctx automatically |
| Stale `task.ctx` after manual edits | Low | Only `task.sh` phase/close should modify it; document this rule |
| Multiple agents writing simultaneously | Low | Single line file; filesystem write is atomic at this size |
| Empty SPEC after graduation | High | Fix `task.sh graduate` to populate SPEC; add validation gate |

## 8. Success Criteria

- [x] `swt.sh ctx set <file>` creates `task.ctx`; `swt.sh ctx show` displays it
- [x] `flow.sh open` reads `task.ctx` and displays task metadata
- [x] `flow.sh check` exits non-zero when no/invalid context exists
- [x] `status.sh` shows active task context at top of output
- [x] `task.sh close` auto-clears `task.ctx` when it points to closed task
- [x] `task.ctx` is gitignored and survives across sessions
- [x] SPEC is fully populated immediately after `task.sh graduate`
- [x] Phase 2+ blocked if SPEC is empty or placeholder-only
- [x] User confirms MVP works as expected

## 9. Out of Scope

- Keyword-based task surfacing in conversation (too many false positives)
- Auto-activation of related tasks without user confirmation
- Complex conflict resolution for simultaneous agent writes
- SPEC template generation with AI assistance (future enhancement)

## 10. Open Questions

- Should `task.ctx` store additional metadata (phase, last updated) or stay single-line?
- What happens when user has multiple projects — one `task.ctx` per project root (current answer: yes)
- Should `swt:flow` auto-create `task.ctx` on Phase 1 entry? (Current: manual via `swt.sh ctx set`)

## 11. References

- Task file: `.tasks/20260427184057_task-first-workflow.md`
- Skills: `swt:flow`, `swt:task`, `swt:status`, `swt:think`, `swt:digest`
- AGENTS.md Section 7: Session Start & Restoration
- AGENTS.md Section 3: The 8-Phase Workflow & Consent Gates

## 12. MVP Definition

- [x] `task.ctx` file tracks active task filename in project root
- [x] `swt.sh ctx set/clear/show` manages context lifecycle
- [x] `flow.sh open/check/status` provides active task engine
- [x] `status.sh` displays active context at top of output
- [x] `swt:think` documents Task-First Workflow rule
- [x] `digest.sh` includes active context in output
- [x] `swt-flow/SKILL.md` updated with task.ctx check
- [x] `AGENTS.md` Section 7 updated with task.ctx step
- [x] `.gitignore` includes `task.ctx`
- [x] `task.sh graduate` populates SPEC from task content
- [x] SPEC-First Rule documented in Phase 1 (swt:flow and AGENTS.md)
- [x] User confirms MVP works as expected
