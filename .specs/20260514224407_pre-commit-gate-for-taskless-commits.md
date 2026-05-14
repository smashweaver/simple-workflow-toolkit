# Spec: pre-commit gate for taskless commits
GATE 2: APPROVED
**Version**: 1.0
**Status**: active
**Linked Task**: .tasks/20260514224123_pre-commit-gate-for-taskless-commits.md

## 1. Problem Statement
Block commits to source files when no SWT task is active, ensuring all code changes are always traceable to an intentional task lifecycle.

## 2. Goals
- [ ] Pre-commit hook reads `task.ctx` and blocks commit if empty or missing.
- [ ] Hook installed automatically by `/swt:flow setup`.
- [ ] Clear error message guides agent/user to open a task first.

## 3. Proposed Solution
- **Scenario A (Discipline)**: Add a rule to `AGENTS.md` — "Never commit without an active task." — **Rejected**: verbal rules are unreliable, as today proved.
- **Scenario B (Automation)**: Pre-commit hook that warns but does not block. — **Rejected**: agents ignore warnings.
- **Scenario C (Enforcement)**: Pre-commit hook that hard-blocks with `exit 1` unless `task.ctx` is non-empty. — **Selected**.
- **User Suggestion**: "What do I need to add to the toolkit?" — this task is the direct answer.

## 4. User Stories
- **US-001**: As an agent, I am physically blocked from committing without an active task.
- **US-002**: As a user, every git commit maps to a `.tasks/` entry.

## 5. Non-Functional Requirements
- Hook must be idempotent (safe to install multiple times).
- Hook must not interfere with non-SWT repositories.

## 6. Implementation Plan
1. Create `skills/swt-task/scripts/hooks/pre-commit` template.
2. Update `task.sh init` (setup) to copy the hook to `.git/hooks/pre-commit`.
3. Update `/swt:flow setup` help text to document the hook.

## 7. Risks & Mitigations
| Risk | Mitigation |
|---|---|
| Hook blocks legitimate sidecar-only commits | Exempt commits where all staged files are under `.tasks/` or `.specs/` |
| Hook not installed on existing projects | Document `/swt:flow setup` as the manual install path |

## 8. Success Criteria
- [ ] `git commit` fails with a clear error when `task.ctx` is empty.
- [ ] `git commit` succeeds normally when a task is mounted.
- [ ] Hook is installed by `/swt:flow setup` automatically.

## 9. Out of Scope
*

## 10. Open Questions
*

## 11. References
*

## 12. MVP Definition
- [ ] `.git/hooks/pre-commit` script implemented and tested.
- [ ] `/swt:flow setup` updated to install the hook.
- [ ] User confirms it blocks a taskless commit correctly.


## Commit Reference


## Guidance
The root cause of today's incident: code was modified and committed with no active task mounted. The task lifecycle enforces ritual *within* a task, but nothing physically blocked changes *outside* of one. This hook closes that gap.

**Key Rules**:
- Hook must hard-block (`exit 1`), not warn.
- Hook must be installed automatically by `/swt:flow setup`.
- Hook must print a clear, actionable error referencing `/swt:flow brainstorm` or `/swt:flow mount`.

## Jailbreak Patterns Observed
| # | Agent | Phase | Violation | Detail |
|---|-------|-------|-----------|--------|
| 1 | Antigravity | Post-close | Taskless commit | Added `--all` flag to `flow.sh` after task was closed, with no active task mounted. |

## Notes
Born from a session where an agent made an unsolicited code change outside any task context, then committed it before anyone noticed.

## Ritual Logs
<!-- RITUAL: phase 4 @ 2026-05-14 22:46:32 (State Verified) -->
<!-- RITUAL: phase 3 @ 2026-05-14 22:46:32 (State Verified) -->
<!-- RITUAL: phase 2 @ 2026-05-14 22:46:31 (State Verified) -->
<!-- RITUAL: phase 1 @ 2026-05-14 22:44:07  -->

## Unresolved Questions
- Should commits touching only `.tasks/` and `.specs/` (sidecar artifacts) be exempt from the gate?

## What This Task Covers
1. **Pre-Commit Hook** — A `.git/hooks/pre-commit` script that checks `task.ctx` before allowing a commit to proceed.
2. **SWT Setup Integration** — Hook is automatically installed by `/swt:flow setup` so all new projects get the gate without manual setup.

## 8. Out of Scope
- Blocking `git add` (too disruptive)
- Cross-repo enforcement

## 9. Open Questions
- Should `--no-verify` bypass be documented as a known escape hatch?

## Checklist
- [/] Phase 1: Plan
- [ ] Phase 2: Analyze
- [ ] Phase 3: Risk Assessment
- [ ] Phase 4: Approval
- [ ] Phase 5: Implement
- [ ] Phase 6: Document
- [ ] Phase 7: Test
- [ ] Phase 8: Review & Refine
- [/] Phase 2
- [/] Phase 3
- [/] Phase 4

## User Stories
- [ ] US-001: As an agent, I am physically blocked from committing code changes unless I have an active task mounted.
- [ ] US-002: As a user, I trust that every commit in the git log maps to a `.tasks/` entry.

## 10. MVP Definition
- [ ] Hook script implemented and tested locally.
- [ ] `/swt:flow setup` installs the hook automatically.
- [ ] User confirms a taskless commit is correctly blocked.
