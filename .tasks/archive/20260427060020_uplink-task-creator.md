# Task: uplink-task-creator
**Created**: 2026-04-27 06:00:20
**Updated**: —
**Completed**: 2026-04-27
**Status**: done
**Priority**: medium          <!-- low | medium | high | critical -->
**Type**: brainstorm          <!-- feature | bugfix | refactor | chore | docs -->
**Stack**: shared             <!-- frontend | backend | shared -->
**Phase**: 1                  <!-- current active phase (0–8) -->
**Spec**: .specs/20260427060259_uplink-task-creator.md
**Blocked By**: —             <!-- task filename or n/a -->

## Core Concept
Enable an agent to "throw" ideas, issues, or tool friction points directly back to the core SWT project's backlog from any active workspace. This acts as a remote `swt:task brainstorm` that bridges the gap between tool usage and tool development.

## Explored Alternatives
- **Scenario A (Simple CLI Bridge)**: A standalone `uplink.sh` script that takes a string, detects `$SWT_HOME`, and writes a raw markdown file to `$SWT_HOME/.tasks/`.
- **Scenario B (Skill-Integrated Context)**: A `swt-uplink` skill that captures the caller's active task, current phase, and project path, injecting this metadata into the remote task for better traceability.
- **Scenario C (Bidirectional Sync)**: A more complex system that allows tracking the status of the "uplinked" task from within the client project (e.g., "Your feedback was graduated to a feature").

## Unresolved Questions
- How do we handle permissions/writing if `SWT_HOME` is a restricted directory?
- What is the fallback behavior if `SWT_HOME` is not set? (Local `.tasks/` with `[META]` tag?)
- Should this be a bash script, or part of the `swt-task` script logic?

## Notes

## Commit Reference


## Checklist
- [ ] Phase 1: Plan
- [ ] Phase 2: Analyze
- [ ] Phase 3: Risk Assessment
- [ ] Phase 4: Approval
- [ ] Phase 5: Implement
- [ ] Phase 6: Document
- [ ] Phase 7: Test
- [ ] Phase 8: Review & Refine
