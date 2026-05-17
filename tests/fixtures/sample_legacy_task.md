# Task: build legacy markdown to html migration converter
**Created**: 2026-05-17 23:06:49
**Updated**: —
**Completed**: —
**Status**: pending
**Priority**: high
**Type**: brainstorm
**Category**: research
**Stack**: shared
**Phase**: 8
**Blocked By**: —
**Spec**: .specs/20260517233130_build-legacy-markdown-to-yaml-migration-converter.md

## What This Task Covers
1. **Markdown AST Parsing**
   - Leverage Python's `markdown-it-py` library and regular expression checks inside `twin.py` to parse task metadata, status, priority, objective, headers, checklists, and ritual logs.
2. **Rich HTML Serializer & Embedded JSON State**
   - Convert the parsed structure into a sleek, premium, self-contained HTML page that:
     * Renders a modern CSS dark-mode dashboard (with interactive styles, checklists, and timelines).
     * Embeds a clean, standard, structured JSON database block inside a `<script type="application/json" id="swt-metadata">` tag at the bottom.
3. **Preservation of History**
   - Guarantee that historical ritual logs, checklists, user stories, and unresolved questions are converted without any data loss.
4. **Comprehensive Unit Testing Suite**
   - Implement dedicated Python unit tests under `tests/` (e.g., `tests/test_migrate.py`) to validate 100% correctness of metadata extraction, checklist states, ritual logs, and JSON extraction/round-trip fidelity.

## Guidance (Read Before Spec/Implementation/Walkthrough)
This task is the core foundational dependency of the **Unified HTML Ecosystem & Workspace Hygiene Epic**. We must build a standalone Python-level parser that can convert legacy Markdown files before any active facade commands shift to native HTML.

**Key Rules**:
- The converter must be completely self-contained in Python (`twin.py`), testable, and expose a clean CLI utility interface.
- 100% round-trip fidelity: converting Markdown to HTML must preserve all checkboxes, comments, and timestamps exactly, placing them in both the visual rendering and the embedded JSON block.

## Objective
Build a robust, highly reliable MD-to-HTML migration parser and serializer inside `twin.py` that ingests legacy Markdown tasks, specs, and digests and converts them to valid Rich HTML files with embedded JSON state with 100% data fidelity.

## Explored Alternatives
- **Scenario A (Discipline)**: Methodology-only. Manually re-write task files into HTML. (Rejected - extremely tedious and error-prone).
- **Scenario B (Automation)**: Build a standalone Python script `migrate.py` to convert Markdown tasks. (Accepted - extremely safe and easily decoupled).
- **Scenario C (Enforcement)**: Integrate the migration script into the setup/upgrade sequence to automate the transition. (Accepted - provides a seamless upgrade path).
- **User Suggestion**: Decouple the converter engine into its own task to break the circular dependency. (Accepted - excellent architecture choice).

## Unresolved Questions
How do we preserve manual, arbitrary comments inserted by users in Markdown files? (Decided: We will parse arbitrary text sections into a generic `notes` block in JSON so they are preserved and rendered).

## Artifact Phase Mapping
| Artifact | Generated | Phase | Gate |
|---|---|---|---|
| `[TS].plan.md` | Phase 1 | Plan | HARD STOP |
| `[TS].tr.md` | Phase 1 | Plan | Roadmap |

## Jailbreak Patterns Observed
| # | Agent | Phase | Violation | Detail |
|---|-------|-------|-----------|--------|
| 1 | — | — | — | — |

## Notes
* **Implementation sequence**:
  1. **Task 1 (This Task)**: Build MD-to-HTML converter engine in Python.
  2. **Task 2**: Build setup/upgrade facade, clean drift, arm hooks, and trigger Task 1's HTML converter.
  3. **Task 3**: Migrate orchestrator shell commands and hooks to natively read and write HTML task databases.

## Ritual Logs
<!-- RITUAL: test pass @ 2026-05-18 05:28:18 (.tests/20260518052814.log) -->
<!-- RITUAL: test pass @ 2026-05-18 05:26:05 (.tests/20260518052601.log) -->
<!-- RITUAL: test pass @ 2026-05-18 05:25:52 (.tests/20260518052548.log) -->
<!-- RITUAL: test pass @ 2026-05-18 05:24:22 (.tests/20260518052418.log) -->
<!-- RITUAL: test pass @ 2026-05-18 05:24:01 (.tests/20260518052357.log) -->
<!-- RITUAL: test pass @ 2026-05-18 05:23:45 (.tests/20260518052341.log) -->
<!-- RITUAL: test pass @ 2026-05-18 05:05:01 (.tests/20260518050457.log) -->
<!-- RITUAL: test pass @ 2026-05-18 05:04:49 (.tests/20260518050444.log) -->
<!-- RITUAL: test pass @ 2026-05-18 04:58:50 (.tests/20260518045457.log) -->
<!-- RITUAL: test pass @ 2026-05-18 04:54:00 (.tests/20260518045346.log) -->
<!-- RITUAL: test pass @ 2026-05-18 04:52:38 (.tests/20260518045213.log) -->
<!-- RITUAL: test pass @ 2026-05-17 23:54:47 (.tests/20260517235443.log) -->
<!-- RITUAL: test pass @ 2026-05-17 23:54:16 (.tests/20260517235412.log) -->
<!-- RITUAL: test fail @ 2026-05-17 23:54:08 (.tests/20260517234342.log) -->
<!-- RITUAL: test fail @ 2026-05-17 23:43:35 (.tests/20260517234250.log) -->
<!-- RITUAL: test pass @ 2026-05-17 23:40:17 (.tests/20260517233957.log) -->
<!-- RITUAL: test pass @ 2026-05-17 23:39:44 (.tests/20260517233915.log) -->
<!-- RITUAL: commit guidelines read -->
<!-- RITUAL: phase 8 @ 2026-05-17 23:38:43 (State Verified) -->
<!-- RITUAL: phase 7 @ 2026-05-17 23:38:42 (State Verified) -->
<!-- RITUAL: phase 6 @ 2026-05-17 23:38:30 (State Verified) -->
<!-- RITUAL: phase 5 @ 2026-05-17 23:37:17 (State Verified) -->
<!-- RITUAL: phase 4 @ 2026-05-17 23:36:22 (State Verified) -->
<!-- RITUAL: phase 3 @ 2026-05-17 23:34:25 (State Verified) -->
<!-- RITUAL: phase 2 @ 2026-05-17 23:34:18 (State Verified) -->
<!-- RITUAL: phase 1 @ 2026-05-17 23:32:11 (Reset via sync-downstream) -->
<!-- RITUAL: phase 1 @ 2026-05-17 23:31:30  -->
<!-- RITUAL: phase 0 @ 2026-05-17 23:06:49 -->

## Commit Reference


## Goals
- [ ] Goal 1: Build the core Markdown AST parser inside `twin.py` to extract metadata, headers, checklists, and ritual logs.
- [ ] Goal 2: Build the Rich HTML serializer that renders a sleek visual glassmorphism dashboard and embeds the formatted JSON state.
- [ ] Goal 3: Add comprehensive Python unit test suites to verify exact round-trip conversion and JSON extraction without data loss.

## User Stories
- [ ] US-001: As a developer, I can migrate all my old Markdown tasks to the new self-contained HTML format in one step without losing my historical checklists or ritual logs.
- [ ] US-002: As an upgrade process, I can call `twin.py` with standard arguments to execute the migration silently on all project files.

## Success Criteria
- [ ] Standalone CLI command in `twin.py` successfully converts any legacy Markdown task/spec/digest.
- [ ] Converted HTML pages contain valid, cleanly formatted, and extractable JSON metadata blocks.
- [ ] Converted HTML pages render beautifully and correctly inside standard web browsers.
- [ ] Checklist and log data are perfectly preserved.

## MVP Definition
- [ ] MD-to-HTML conversion engine active inside `twin.py`.
- [ ] Unit tests proving zero data loss and flawless JSON extraction for standard tasks, specs, and digests.
- [ ] Decoupled utility is ready to be consumed by the setup facade.

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
- [/] Phase 5
- [/] Phase 6
- [/] Phase 7
- [/] Phase 8
