# Task: task-first-workflow
**Created**: 2026-04-27 18:40:57
**Updated**: 2026-04-28 11:16:02
**Completed**: 2026-04-28 11:16:02
**Status**: done
**Priority**: high
**Type**: brainstorm
**Stack**: shared
**Phase**: 8
**Spec**: .specs/20260427234312_task-first-workflow.md
**Blocked By**: —

## Core Concept
When users raise issues or describe features during a session, SWT agents should proactively guide them to create a task file first—either a new brainstorm task to flesh out the issue, or activate an existing relevant task. This keeps all work tracked and prevents "vibecoding" (untracked problem-solving).

## Explored Alternatives

- **Scenario A (Discipline)**: Add guidance to AGENTS.md that agents MUST surface task creation when detecting exploratory conversation. No scripts needed.
- **Scenario B (Automation)**: Create a smart task hook in the digest/status scripts that detects relevant tasks based on keywords in the conversation.
- **Scenario C (Enforcement)**: Implement hard gates that block implementation/analysis until a task file is created or activated for the current topic.

## Unresolved Questions

- How should keyword matching work without being too aggressive (false positives)?
- Should auto-activation only surface tasks, or also change the active task context?
- What about quick one-off questions that don't need a task?

## Notes

**Session Start Discussion (2026-04-27):**
- Current AGENTS.md rule: "Invoke swt:status at session start" — not automatically triggered
- Problem: opencode/claude/etc read AGENTS.md but don't act on it without explicit user command
- Proposal: Update CLAUDE.md/GEMINI.md to explicitly invoke swt:status
- Alternatively: Make swt:status read AGENTS.md automatically

**Midstream Issue Rule (agreed 2026-04-27):**
- When user raises new issue mid-session → agent asks: "Want me to create a brainstorm task for this?"
- Simple rule, not complex keyword matching
- User can always say no for quick questions

**Iterative Brainstorming Rule:**
- Agent asks: "Want me to create a task for this?"
- User decides yes/no
- If yes → create task, Notes capture discussion so far
- If no → continue without task (quick question)

**Trigger Points (when agent asks):**
- Session start (no task context)
- Mid-discussion when user raises new issue/topic
- During any phase of task work when user mentions something for later
- When user shifts to new feature/problem mid-implementation
- Agent should populate new task with relevant context from discussion

**Core Principle (non-negotiable):**
- Agent MUST NOT start coding outside of swt:flow phases
- All work must go through the 8-phase workflow
- If user raises issue → create task → graduate → then code
- No "quick coding" or "just show me" outside task context
- **SPEC-First Rule**: After graduation, SPEC is populated BEFORE Phase 2+ (it is the source of truth for implementation)

**Session Continuity (why this matters):**
- Task file = memory across sessions and agents
- Different agent (claude, antigravity, etc) opens task.ctx → reads task → knows context
- Even if not the same agent, they can pick up where left off
- Brainstorm captures iterative thought so it's not lost

**Temp Task Reference (agreed 2026-04-27):**
- Filename: `task.ctx` (in project root)
- Format: Contains current task filename (e.g., `20260427184057_task-first-workflow`)
- Gitignored: Yes (add to .gitignore)
- Agent reads at start to know current context

**Logic:**
1. Agent reads `task.ctx` at session start
2. If file exists → load that task context
3. If doesn't exist → no active task, ask: "What would you like to work on?"

**Related existing behaviors:**
- `/swt:task brainstorm` exists for Phase 0 ideation
- `/swt:task list --open` shows active tasks
- No current keyword-based task surfacing in conversation

**Proposed trigger signals:**
- User says "I want to...", "can you help me...", "I'm trying to..."
- User describes a problem or feature without referencing a task
- Agent starts planning (Phase 1) without an active task context

**SPEC Formalization (2026-04-27):**
- The 12-section SPEC structure (Problem Statement, Goals, Proposed Solution, User Stories, Non-Functional Requirements, Implementation Plan, Risks & Mitigations, Success Criteria, Out of Scope, Open Questions, References, MVP Definition) should be formalized in `swt:spec`.
- `swt:spec` currently has a 16-section template (SKILL.md lines 89-250) — the 12-section version used in this task is cleaner and more focused.
- **Action**: Update `swt:spec` SKILL.md to adopt the 12-section structure as the canonical template for `task.sh graduate` and `/swt:spec` invocations.
- The 12 sections: 1.Problem Statement, 2.Goals, 3.Proposed Solution, 4.User Stories, 5.Non-Functional Requirements, 6.Implementation Plan, 7.Risks & Mitigations, 8.Success Criteria, 9.Out of Scope, 10.Open Questions, 11.References, 12.MVP Definition.
- Remove the 16-section version's overlap (FR/NFR/Data Model/API Contracts merged into relevant sections).

**Recent Alignment (2026-04-27):**
- **Observation**: `swt:flow` is currently a "script-less" skill (passive guidance only).
- **Decision**: Upgrade `swt:flow` to an active engine. 
- **Action**: Create `skills/swt-flow/scripts/flow.sh` to manage `/swt:flow open` and `task.ctx` state validation.
- **Goal**: Move from "behavioral mandate" to "scripted enforcement."
- **Critical**: SPEC must be populated from task's Core Concept, Explored Alternatives, and Notes immediately after graduation — BEFORE any Phase 2+ work.

## Phase 2 & 3 Guidance

Per AGENTS.md: *"For trivial changes, Scenarios B and C can be marked as 'N/A' or 'Not recommended for simplicity.'"*

**Trivial changes** (script-only, config-only, no security surface, no performance impact, no breaking API changes):
- Phase 2 (Analyze): N/A — no deep codebase impact analysis needed
- Phase 3 (Risk Assessment): N/A — no meaningful security/perf/compatibility risks

**Non-trivial changes** (new auth system, database schema changes, new API endpoints, performance-critical paths):
- Phase 2 (Analyze): Map all callers, identify "Affected Concepts" via graphify, assess state/contract changes
- Phase 3 (Risk Assessment): Flag security risks (auth bypass, injection), performance bottlenecks, breaking API changes — define mitigations

**This task** (`task-first-workflow`): Scripts-only, no security surface, no performance impact, no breaking API changes → Phase 2 & 3 are N/A.

## Commit Reference
56c6844

## Checklist
- [x] Phase 1: Plan
- [x] Phase 2: Analyze
- [x] Phase 3: Risk Assessment
- [x] Phase 4: Approval
- [x] Phase 5: Implement
- [x] Phase 6: Document
- [x] Phase 7: Test
- [x] Phase 8: Review & Refine
<!-- RITUAL: phase 1 @ 2026-04-27 23:43:12 -->
<!-- RITUAL: phase 5 @ 2026-04-28 00:16:04 -->
<!-- RITUAL: phase 7 @ 2026-04-28 05:24:28 -->
<!-- RITUAL: phase 8 @ 2026-04-28 05:25:23 -->
