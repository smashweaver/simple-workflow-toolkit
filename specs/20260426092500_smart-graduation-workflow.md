# Spec: Smart Graduation Workflow (swt.sh graduate)

**Version**: 0.1
**Status**: draft
**Author**: Gemini CLI
**Created**: 2026-04-26
**Updated**: 2026-04-26
**Linked Task**: .tasks/20260426090529_integrating-swt-spec-into-the-graduation-workflow.md

---

## 1. Problem Statement
The current SWT workflow lacks a formal mechanism for transitioning from Phase 0 (Ideate) to Phase 1 (Plan). Agents often manually increment the phase number, bypassing the mandatory creation of a `SPEC.md` artifact, which leads to "ritual drift" and ungrounded planning.

## 2. Goals
- Automate the graduation ritual to ensure consistency.
- Enforce the creation of a `SPEC.md` for significant features.
- Provide a "Lite" path for surgical refactors to maintain iterative flow.
- Seamlessly update task metadata (Phase, Status, Type).

## 3. Non-Goals
- Replacing manual task editing entirely.
- Automating the implementation (Phase 5).

## 4. Users & Stakeholders
| Role | Description | Primary? |
|------|-------------|----------|
| AI Agent | Executes the graduation command to stay in protocol. | Yes |
| User | Reviews the generated spec and provides consent. | Yes |

## 5. User Stories
**US-001**: As an Agent, I want a `graduate` command so that I can transition a task to Phase 1 without manual file editing errors.
- [ ] AC1: Running `swt.sh graduate <file>` updates Phase to 1 and Status to pending.

**US-002**: As a User, I want the agent to distinguish between features and refactors so that I don't have to review a 5-page spec for a simple logic change.
- [ ] AC1: If `Type` is `refactor`, the agent appends a `## Verification Checklist` to the task instead of a separate file.

## 6. Functional Requirements
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Implement `swt.sh graduate <task_file>` in `task.sh`. | Must |
| FR-002 | Prompt for/Generate `SPEC.md` during graduation of `Type: feature`. | Must |
| FR-003 | Update task metadata: Phase 0 -> 1, Status ideating -> pending. | Must |
| FR-004 | Add `**Spec**` field to task file pointing to the new artifact. | Must |

## 12. MVP Definition
**Included in MVP:**
- `graduate` command in `task.sh`.
- Automatic `SPEC.md` scaffolding for features.
- Metadata updates for the task file.

---

## 16. Revision History
| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 0.1 | 2026-04-26 | Gemini | Initial draft for Smart Graduation. |
